output "repository_url" {
  description = "Full ECR repository URL - used in Jenkinsfile for docker push and later in Kubernetes manifests for the image reference"
  value       = aws_ecr_repository.app.repository_url
}

output "repository_name" {
  value = aws_ecr_repository.app.name
}

output "repository_arn" {
  value = aws_ecr_repository.app.arn
}
