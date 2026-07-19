# ============================================================================
# ADDITIONAL IAM PERMISSION FOR JENKINS: ECR PUSH
#
# This file lives in the jenkins-ec2 Terraform layer (not ecr/), because
# IAM roles/policies attached to the Jenkins EC2 instance belong
# conceptually with the instance's other IAM config (iam.tf from Step 6).
# It reads the ECR repository's ARN from the ecr layer's remote state -
# exactly the cross-layer reference pattern used throughout this project.
#
# This is the FIRST of the "add permissions incrementally, exactly when a
# stage needs them" promises from Step 6 being fulfilled.
# ============================================================================

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket = "fintech-payment-platform-tfstate"
    key    = "ecr/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_iam_role_policy" "jenkins_ecr_push" {
  name = "${var.project_name}-jenkins-ecr-push"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # GetAuthorizationToken is account-wide (not resource-scoped) -
        # this is a hard AWS requirement for the ECR login step
        # (`aws ecr get-login-password`), not a permission we can narrow
        # further.
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        # Everything else IS scoped to exactly this one repository ARN -
        # Jenkins cannot push to, pull from, or modify any other ECR
        # repository that might exist in this AWS account.
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = data.terraform_remote_state.ecr.outputs.repository_arn
      }
    ]
  })
}
