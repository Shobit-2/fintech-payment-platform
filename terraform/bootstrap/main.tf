# ============================================================================
# BOOTSTRAP - run this ONCE, manually, before anything else.
#
# This creates the S3 bucket + DynamoDB table that ALL other Terraform
# configs in this repo will use as their remote backend. It intentionally
# uses local state itself (no backend block) - you can't reference a backend
# that doesn't exist yet.
#
# Usage:
#   cd terraform/bootstrap
#   terraform init
#   terraform apply
#
# Run this exactly once per AWS account. Never destroy this unless you are
# tearing down the entire project permanently - destroying it deletes your
# state history for everything else.
# ============================================================================

terraform {
  required_version = ">= 1.6.0"
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

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state. Must be unique across ALL AWS accounts worldwide, not just yours - S3 bucket names are a global namespace."
  type        = string
  default     = "fintech-payment-platform-tfstate"
}

# S3 bucket to hold the actual .tfstate files
resource "aws_s3_bucket" "tf_state" {
  bucket = var.state_bucket_name

  # Prevents accidental deletion via `terraform destroy` run against this
  # bootstrap config itself - you'd have to remove this protection
  # deliberately first.
  lifecycle {
    prevent_destroy = true
  }
}

# Versioning: every state change creates a new object version. If a bad
# `terraform apply` corrupts state, you can roll back to a previous version -
# this has saved real production teams from state-related disasters.
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# State files can contain sensitive data (e.g. RDS passwords if not handled
# carefully) - encryption at rest is a baseline security requirement.
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access - state files must never be internet-accessible.
resource "aws_s3_bucket_public_access_block" "tf_state_block" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking. Prevents two people (or two Jenkins jobs)
# from running `terraform apply` at the same time and corrupting state -
# Terraform acquires a lock row here before every apply/plan and releases it
# after.
resource "aws_dynamodb_table" "tf_lock" {
  name         = "fintech-payment-platform-tf-lock"
  billing_mode = "PAY_PER_REQUEST" # no fixed cost - pennies for this workload
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.tf_lock.name
}
