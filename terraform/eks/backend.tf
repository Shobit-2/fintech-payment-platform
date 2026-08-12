terraform {
  backend "s3" {
    bucket = "fintech-payment-platform-tfstate"
    key    = "fintech/eks/terraform.tfstate"
    region = "us-east-1"
  }
}