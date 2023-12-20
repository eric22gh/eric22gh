terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.1"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
  #access_key = var.access_key # para que ese codigo se pueda conectar a aws, pero es mas seguro por la terminal
  # secret_key = var.secret_key
  default_tags {
    tags = var.tags_project
  }
}
