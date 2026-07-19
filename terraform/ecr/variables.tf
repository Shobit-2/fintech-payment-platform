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

variable "image_retention_count" {
  description = "Number of most-recent images to keep per repository before older ones are automatically expired. Keeps ECR storage cost bounded - see cost discussion from Step 1."
  type        = number
  default     = 10
}
