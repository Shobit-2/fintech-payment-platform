variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
  default     = "fintech"
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins - your account is limited to t3.small/c7.large"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB. Jenkins + Docker images + build workspace need real space - 8GB default is too small."
  type        = number
  default     = 30
}

variable "public_key_path" {
  description = "Path to YOUR local SSH public key file (e.g. ~/.ssh/id_rsa.pub or ~/.ssh/fintech-jenkins.pub). Generate one with `ssh-keygen -t ed25519` if you don't have one. Terraform imports the PUBLIC key only - your private key never leaves your machine."
  type        = string
}
