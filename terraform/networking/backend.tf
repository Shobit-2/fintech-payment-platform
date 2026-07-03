# Remote backend - points at the bucket created by terraform/bootstrap.
# NOTE: bucket/dynamodb_table names below must match bootstrap's outputs.
# NOTE 2: Terraform backend blocks cannot use variables - values must be
# hardcoded literals. This is a known Terraform limitation, not an oversight.
terraform {
  backend "s3" {
    bucket         = "fintech-payment-platform-tfstate"
    key            = "networking/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fintech-payment-platform-tf-lock"
    encrypt        = true
  }
}
