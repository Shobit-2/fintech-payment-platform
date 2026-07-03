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

  # OPEN TO THE INTERNET (0.0.0.0/0) - a deliberate choice for this learning
  # project, made after discussing the tradeoff. In a real production
  # environment this would instead be restricted to a VPN CIDR, a bastion
  # host, or specific known IPs. Mitigations applied elsewhere to offset
  # this: SSH will be key-only (no password auth), and Jenkins itself will
  # be configured with a strong admin password + matrix-based authorization
  # in Step 6 (Jenkins setup) - never leave Jenkins on its default
  # "no login required" initial state when internet-exposed.
  ingress {
    description = "Jenkins web UI - open to internet (see comment above)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH - open to internet (see comment above); key-only auth enforced at OS level"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
