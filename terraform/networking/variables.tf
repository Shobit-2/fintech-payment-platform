variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name, used in resource naming/tagging"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
  default     = "fintech"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Two AZs is the minimum EKS requires for its control plane. We keep this
# list configurable, not hardcoded, so this same config works if you deploy
# to a different region later (region -> different AZ names).
variable "availability_zones" {
  description = "AZs to spread subnets across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# Cost lever: a single NAT Gateway (shared by both private subnets) is
# cheaper than one-per-AZ, at the cost of a small availability tradeoff
# (if that AZ's NAT Gateway has an issue, both private subnets lose
# internet egress). For a learning/demo project, single is the right
# default; enterprises handling real production traffic typically pay for
# one NAT Gateway per AZ.
variable "single_nat_gateway" {
  description = "If true, create only one NAT Gateway shared across all private subnets (cheaper). If false, one per AZ (more resilient, more expensive)."
  type        = bool
  default     = true
}

# NOTE: an admin_ip_cidr variable previously restricted Jenkins UI/SSH to a
# single IP. Per project decision, Jenkins UI and SSH are instead open to
# 0.0.0.0/0 for convenience (see security-groups.tf comments for the
# tradeoff and mitigations). Removed here to avoid a declared-but-unused
# variable; reintroduce it if you tighten access later.
