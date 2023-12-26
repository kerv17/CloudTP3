variable "aws_region" {
  description = "The AWS region"
  default     = "us-east-1"
}

variable "aws_zone" {
  description = "The AWS zone"
  default     = "us-east-1c"
}

variable "ami_id" {
  description = "The AMI ID for the instances"
  default     = "ami-0149b2da6ceec4bb0" // ami_id for us-east-1 linux 
}

variable "access_key" {
  description = "AWS access key"
}

variable "secret_key" {
  description = "AWS secret key"
}

variable "token" {
  description = "AWS session token (optional)"
}

variable "key_name" {
  description = "value of the key name"
  default = "vockey"
}

provider "aws" {
  region = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
  token = var.token
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

resource "aws_security_group" "security_gp" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "standalone" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.security_gp.id]
  availability_zone      = var.aws_zone
  user_data              = file("standalone.sh")
  key_name               = var.key_name

  tags = {
    "Name" = "Standalone"
  }
}

resource "aws_instance" "cluster-master" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.security_gp.id]
  availability_zone      = var.aws_zone
  key_name               = var.key_name
  tags = {
    "Name" = "Cluster-master"
  }
}

resource "aws_instance" "cluster-slave-1" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.security_gp.id]
  availability_zone      = var.aws_zone
  key_name               = var.key_name
  tags = {
    "Name" = "slave-1"
  }
}

resource "aws_instance" "cluster-slave-2" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.security_gp.id]
  availability_zone      = var.aws_zone
  key_name               = var.key_name
  tags = {
    "Name" = "slave-2"
  }
}

resource "aws_instance" "cluster-slave-3" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.security_gp.id]
  availability_zone      = var.aws_zone
  key_name               = var.key_name
  tags = {
    "Name" = "slave-3"
  }
}

resource "aws_instance" "proxy" {
  ami                    = var.ami_id
  instance_type          = "t2.large"
  vpc_security_group_ids = [aws_security_group.security_gp.id]
  availability_zone      = var.aws_zone
  key_name               = var.key_name
  tags = {
    "Name" = "proxy"
  }
}