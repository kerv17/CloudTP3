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
  default = "vockey2"
}

variable "ips_key_name" {
  description = "value of the key name"
  default = "vockey2.pem"
  
}
provider "aws" {
  region = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
  token = var.token
}

data "aws_vpc" "default" {
  default = true
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

//////////////////////////////////////// SECURITY GROUPS ////////////////////////////////////////
resource "aws_security_group" "gatekeeper_security_gp" {
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

resource "aws_security_group" "trusted_host_security_gp" {
  vpc_id = data.aws_vpc.default.id

# Allow ingress traffic from the gatekeeper server
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    security_groups = [aws_security_group.gatekeeper_security_gp.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
}

resource "aws_security_group" "proxy_security_gp" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    security_groups = [aws_security_group.trusted_host_security_gp.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
}

resource "aws_security_group" "security_gp" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
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

resource "aws_security_group" "mysql_security_gp" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 1186
    to_port     = 1186
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting this to specific IPs/subnets for security
    ipv6_cidr_blocks = ["::/0"] # Optional for IPv6
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
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

//////////////////////////////////////// INSTANCES ////////////////////////////////////////
resource "aws_instance" "standalone" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysql_security_gp.id]
  availability_zone      = var.aws_zone
  user_data              = file("./standalone.sh")
  key_name               = var.key_name

  tags = {
    "Name" = "Standalone"
  }
}

resource "aws_instance" "cluster_master" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysql_security_gp.id]
  availability_zone      = var.aws_zone
  user_data              = file("./master.sh")
  key_name               = var.key_name

  tags = {
    "Name" = "Cluster Master"
  }

  provisioner "file" {
    source      = "ips.sh"
    destination = "/tmp/ips.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("vockey2.pem")
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "cluster_slave" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysql_security_gp.id]
  availability_zone      = var.aws_zone
  user_data              = file("./slave.sh")
  key_name               = var.key_name
  count                  = 3

  tags = {
    "Name" = "Cluster Slave ${count.index}"
  }

  provisioner "file" {
    source      = "ips.sh"
    destination = "/tmp/ips.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("vockey2.pem")
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "proxy" {
  ami                    = var.ami_id
  instance_type          = "t2.large"
  vpc_security_group_ids = [aws_security_group.mysql_security_gp.id]
  availability_zone      = var.aws_zone
  user_data              = file("./proxy.sh")
  key_name               = var.key_name

  tags = {
    "Name" = "Proxy"
  }

  provisioner "file" {
    source      = "ips.sh"
    destination = "/tmp/ips.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("vockey2.pem")
      host        = self.public_ip
    }
  }
}


resource "aws_instance" "gatekeeper" {
  ami                     = "ami-0fc5d935ebf8bc3bc"
  instance_type           = "t2.large"
  vpc_security_group_ids  = [aws_security_group.gatekeeper_security_gp.id]
  availability_zone       = var.aws_zone
  user_data               = file("./gatekeeper.sh")
  key_name                = var.key_name

  tags = {
    Name = "Gatekeeper Server"
  }
  provisioner "file" {
    source      = "ips.sh"
    destination = "/tmp/ips.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("vockey2.pem")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "vockey2.pem"
    destination = "/home/ubuntu/vockey2.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("vockey2.pem")
      host        = self.public_ip
    }
  }
}


resource "aws_instance" "trusted_host" {
  ami                     = "ami-0fc5d935ebf8bc3bc"
  instance_type           = "t2.large"
  vpc_security_group_ids  = [aws_security_group.gatekeeper_security_gp.id]
  availability_zone       = var.aws_zone
  user_data               = file("./trusted_host.sh")
  key_name                = var.key_name

  tags = {
    Name = "Gatekeeper Server"
  }

  provisioner "file" {
    source      = "ips.sh"
    destination = "/tmp/ips.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("vockey2.pem")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "vockey2.pem"
    destination = "/home/ubuntu/vockey2.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("vockey2.pem")
      host        = self.public_ip
    }
  }
}

//////////////////////////////////////// OUTPUTS ////////////////////////////////////////



output "standalone_dns" {
  description = "The DNS of the standalone instance"
  value       = aws_instance.standalone.public_dns
}
output "cluster_master_dns" {
  description = "The DNS of the cluster master instance"
  value       = aws_instance.cluster_master.public_dns 
}

output "cluster_slave_dns" {
  description = "The DNS of the cluster slave instance"
  value       = aws_instance.cluster_slave.*.public_dns
}

output "proxy_dns" {
  description = "The DNS of the proxy instance"
  value       = aws_instance.proxy.public_dns
}

output "gatekeeper_dns" {
  description = "The DNS of the gatekeeper instance"
  value       = aws_instance.gatekeeper.public_dns
  
}
output "trusted_host_dns" {
  description = "The DNS of the trusted host instance"
  value       = aws_instance.trusted_host.public_dns
}