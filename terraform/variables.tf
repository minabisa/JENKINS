
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Your public IP / CIDR for SSH (example: 1.2.3.4/32). For lab you can use 0.0.0.0/0 but it's not safe."
  default     = "0.0.0.0/0"
}

variable "allowed_jenkins_cidr" {
  type        = string
  description = "Who can access Jenkins UI (8080). For lab you can use 0.0.0.0/0"
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to your SSH public key, used to create AWS key pair"
}

