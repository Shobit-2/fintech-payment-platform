terraform {
  backend "s3" {
    bucket         = "fintech-payment-platform-tfstate"
    key            = "ecr/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fintech-payment-platform-tf-lock"
    encrypt        = true
  }
}
