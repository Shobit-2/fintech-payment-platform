# ============================================================================
# SECURITY GROUPS
# Think of these as stateful firewalls attached to resources (not subnets).
# "Stateful" means: if you allow inbound traffic, the matching outbound
# response is automatically allowed back out - you don't need a matching
# outbound rule for replies.
# ============================================================================

# --- Jenkins EC2 Security Group ---
resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security group for the Jenkins EC2 instance"
  vpc_id      = aws_vpc.main.id

  # Jenkins web UI. Restrict to your IP in production - 0.0.0.0/0 is used
  # here only because this is a learning project; see variable below.
  ingress {
    description = "Jenkins web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  egress {
    description = "Allow all outbound (Jenkins needs to reach GitHub, ECR, Maven Central, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-jenkins-sg"
  }
}

# --- RDS Security Group ---
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL - only accepts traffic from EKS nodes and Jenkins"
  vpc_id      = aws_vpc.main.id

  # Deliberately NO 0.0.0.0/0 ingress rule anywhere in this security group.
  # Database access is restricted to specific security groups only (defined
  # via aws_security_group_rule below, once the EKS node SG exists in a
  # later Terraform layer) - this is why RDS lives in a private subnet AND
  # has a locked-down security group: defense in depth.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# Allow Jenkins to reach RDS directly - useful for running Flyway migrations
# or smoke-testing DB connectivity from the CI pipeline without going
# through the full EKS deployment.
resource "aws_security_group_rule" "rds_from_jenkins" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.jenkins.id
  description               = "Allow Jenkins to reach Postgres for migrations/testing"
}

# NOTE: a rule allowing EKS worker nodes -> RDS on port 5432 will be added
# in terraform/eks (a later step), once the EKS node security group exists.
# This is a deliberate example of how Terraform configs reference each other
# across layers via remote state data sources - covered when we build EKS.
