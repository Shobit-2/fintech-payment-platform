# ============================================================================
# DATA SOURCES
# These read existing information rather than create anything.
# ============================================================================

# Reads the networking layer's state directly out of S3. This is how
# separate Terraform layers reference each other's resources without
# duplicating their definitions - "networking" already created the VPC and
# subnets; we just need their IDs here.
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "fintech-payment-platform-tfstate"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# Always fetch the latest official Ubuntu 22.04 LTS AMI rather than
# hardcoding an AMI ID. AMI IDs are region-specific and Canonical publishes
# new patched versions regularly - hardcoding one means you're stuck on a
# stale, potentially vulnerable image forever.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}
