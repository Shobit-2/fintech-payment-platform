# ============================================================================
# ECR REPOSITORY
# Central, IAM-secured storage for our built container images. EKS (Stage
# 8/9) will pull directly from here.
# ============================================================================

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-payment-platform"
  image_tag_mutability = "IMMUTABLE" # a given tag can never be overwritten once pushed -
                                      # matches our build-number+commit-SHA tagging scheme
                                      # from the Jenkinsfile: once pushed, that exact tag
                                      # is a permanent, trustworthy reference.

  image_scanning_configuration {
    scan_on_push = true # ECR's own basic vulnerability scan runs automatically on
                         # every push, IN ADDITION to Trivy in the pipeline - defense
                         # in depth, and a second opinion using a different scanner
                         # engine/database than Trivy.
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-payment-platform"
  }
}

# Lifecycle policy: automatically expire old images so ECR storage cost
# doesn't grow unbounded as the pipeline runs day after day (recall from
# Step 1's cost discussion: ECR is cheap per-GB, but sloppy tag retention
# over months/years is the one way it stops being a rounding error).
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the most recent ${var.image_retention_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
