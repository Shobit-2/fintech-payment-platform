# ============================================================================
# IAM ROLE FOR JENKINS EC2
#
# Concept: an IAM ROLE is a set of permissions that AWS resources (not
# people) can assume. An INSTANCE PROFILE is the wrapper that lets an EC2
# instance actually use a role. When attached, the EC2 instance can call AWS
# APIs (e.g. "push image to ECR") using short-lived, auto-rotated
# credentials fetched from the instance metadata service - Jenkins code
# never needs a hardcoded AWS access key/secret sitting in a config file
# where it could leak.
#
# We start this role with almost NO permissions. As each pipeline stage is
# built (ECR push in Stage 7, EKS deploy in Stage 8/9), we will come back
# and attach exactly the permission that stage needs - never more. This is
# the "least privilege, added incrementally" pattern real platform teams
# use, rather than attaching AdministratorAccess out of convenience (a very
# common real-world security mistake).
# ============================================================================

resource "aws_iam_role" "jenkins" {
  name = "${var.project_name}-jenkins-role"

  # Trust policy: WHO is allowed to assume this role. Here, only the EC2
  # service itself (i.e. an EC2 instance with this role attached) - not
  # any arbitrary AWS user or account.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Baseline permission: lets Jenkins (via AWS CLI/SSM agent later) send logs
# and basic metrics to CloudWatch. Harmless, broadly useful, and a common
# starting point.
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Allows using AWS Systems Manager Session Manager to shell into the
# instance through the AWS Console/CLI WITHOUT opening port 22 or managing
# SSH keys for this purpose. We're still using SSH directly per your
# earlier choice (open to internet), but this is added as a free backup
# access method with zero extra exposure - it doesn't open any port at all.
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project_name}-jenkins-instance-profile"
  role = aws_iam_role.jenkins.name
}

# NOTE for future steps:
#   Stage 7 (push to ECR)      -> attach ecr:GetAuthorizationToken, ecr:PutImage, etc.
#   Stage 8/9 (deploy to EKS)  -> attach eks:DescribeCluster + map this role
#                                  into the EKS aws-auth ConfigMap
# Both will be added via aws_iam_role_policy resources appended to this file
# when we reach those stages - not now.
