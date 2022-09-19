terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2pwn" {
  ami                    = var.ami_id
  instance_type          = var.ami_type
  key_name               = var.ami_key_pair_name
  vpc_security_group_ids = ["${aws_security_group.allow_http_ssh.id}"]
  tags = {
    Name = "${var.ami_name}"
  }

}

resource "aws_key_pair" "deployer" {
  key_name   = var.ami_key_pair_name
  public_key = var.ami_pub_key
}

output "instance_ip" {
  description = "Public IP address of the EC2 Instance"
  value       = aws_instance.ec2pwn.public_ip
}
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ec2pwn.id
}
