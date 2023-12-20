variable "tags_project" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    environment = "dev"
    owner       = "Edwards"
    region      = "sa-east-1"
    cloud       = "aws"
    IAC_version = "Terraform"
    project     = "practica_9"
    team        = "architects"
    company     = "bacalpo"
  }

}

variable "vpc_sao_paulo_cidr" {
  default     = "38.10.0.0/16"
  description = "The cidr of the sao_paulo vpc"
  type        = string
  sensitive   = true
}
variable "subnet_public_cidr" {
  default     = ["38.10.1.0/25", "38.10.2.0/25"]
  description = "The cidr of the public subnet"
  type        = list(any)
  sensitive   = true
}
variable "subnet_private_cidr" {
  default     = ["38.10.3.0/25", "38.10.4.0/25"]
  description = "The cidr of the private subnet"
  type        = list(any)
  sensitive   = true
}

variable "ingress_port_list" {
  description = "List of ingress ports"
  type        = list(number)
  default     = [22, 80, 3306]
}

variable "egress_port_list" {
  description = "List of egress ports"
  type        = list(number)
  default     = [0]
}

/* variable "access_key" {

}

variable "secret_key" {
}
 */

variable "availability_zones" {
  default = ["sa-east-1a", "sa-east-1c"]
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = "sao_paulo"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Enable single NAT gateway"
  type        = bool
  default     = true
}

variable "count_server" {
  description = "Number of servers"
  type        = number
  default     = 4
}

variable "ami" {
  description = "Amazon Machine Image"
  type        = string
  default     = "ami-05dc908211c15c11d"

}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t2.micro"

}

variable "associate_public_ip_address" {
  description = "Associate public ip address"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "Key name"
  type        = string
  default     = "DOR"
}

variable "max_size" {
  description = "Max size"
  type        = number
  default     = 6

}

variable "min_size" {
  description = "Min size"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired capacity"
  type        = number
  default     = 4
}

