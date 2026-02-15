
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
}

# Latest Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Upload your public key to AWS as a key pair
resource "aws_key_pair" "lab_jenkins_key" {
  key_name   = "lab_jenkins_key.pub"
  public_key = file(var.ssh_public_key_path)
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH + Jenkins UI"

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_jenkins_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for App Server
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH + HTTP"

  # SSH from your IP (so you can log in if needed)
  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # SSH from Jenkins SG (so Ansible from Jenkins can connect)
  ingress {
    description     = "SSH from Jenkins server"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_sg.id]
  }

  # HTTP for Nginx container
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Jenkins EC2 (bootstraps Jenkins container automatically using user_data)
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.lab_jenkins_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = file("${path.module}/jenkins_user_data.sh")

  tags = {
    Name = "lab-jenkins-server"
  }
}

# App EC2 (will be configured by Ansible from Jenkins pipeline)
resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.lab_jenkins_key.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "lab-app-server"
  }
}
