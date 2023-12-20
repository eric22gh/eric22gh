# module "network_infrastructure" 
module "network" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "5.2.0"
  name               = var.name
  cidr               = var.vpc_sao_paulo_cidr
  azs                = var.availability_zones
  private_subnets    = var.subnet_private_cidr
  public_subnets     = var.subnet_public_cidr
  enable_nat_gateway = var.enable_nat_gateway
}

# building an autoscaling group

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.name}_ASG"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = module.network.public_subnets
  launch_configuration      = aws_launch_configuration.lc.name
  health_check_type         = "EC2"
  health_check_grace_period = 500
  target_group_arns         = [aws_alb_target_group.tg_sao_paulo.arn]
  tag {
    key                 = "Name"
    value               = "${var.name}_asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "asg_policy" {
  name                   = "${var.name}_asg_policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0

  }
}
# building a launch configuration

resource "aws_launch_configuration" "lc" {
  name                        = "${var.name}_lc"
  image_id                    = var.ami
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.sg.id]
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.key_name
  user_data                   = <<-EOF
    #!/bin/bash
    yum update -y
    yum install nginx -y
    service nginx start
    systemctl enable nginx
    chkconfig nginx on
    EOF
  lifecycle {
    create_before_destroy = true

  }
}

# building a security group

resource "aws_security_group" "sg" {
  name   = "sao_paulo_sg"
  vpc_id = module.network.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_port_list
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}_sg"
  }
}

# building an alb security group

resource "aws_security_group" "sg_alb" {
  name   = "${var.name}_sg_alb"
  vpc_id = module.network.vpc_id
  dynamic "ingress" {
    for_each = var.ingress_port_list
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}_sg_alb"

  }
}

# building an alb

resource "aws_alb" "alb" {
  name               = "sao-paulo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = module.network.public_subnets
  tags = {
    Name = "${var.name}_alb"
  }
}

# building an alb target group

resource "aws_alb_target_group" "tg_sao_paulo" {
  name        = "sao-paulo-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  health_check {
    healthy_threshold = 5
    interval          = 50
    protocol          = "HTTP"
    matcher           = "200"
    timeout           = 3
    path              = "/"
    port              = "traffic-port"
  }
  vpc_id = module.network.vpc_id
  tags = {
    Name = "${var.name}_tg"
  }
}

# building an alb listener

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.tg_sao_paulo.arn
  }
}

# building an rds subnet group

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.name}_db_subnet_group"
  subnet_ids = module.network.private_subnets
  tags = {
    Name = "${var.name}_db_subnet_group"
  }
}

# building an rds security group

resource "aws_security_group" "db_security_group" {
  name        = "db_security_group"
  description = "Security group for RDS MySQL"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db_security_group"
  }
}

# building an rds instance of mysql

resource "aws_db_instance" "myrds" {
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                 = "mysql"
  engine_version         = "8.0.33"
  instance_class         = "db.t2.micro"
  storage_type           = "gp2"
  username               = "admin"
  password               = "password123"
  parameter_group_name   = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  db_name                = "db_ventas_sao_paulo"
  port                   = 3306
  multi_az               = true
  #publicly_accessible  = true # If you want your database to be publicly accessible
  skip_final_snapshot  = true # If you want to skip final snapshot
  tags                 = var.tags_project
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
}
