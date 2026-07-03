# These outputs are how later Terraform layers (jenkins-ec2, eks, rds)
# reference this layer's resources - via `terraform_remote_state` data
# sources pointing at this state file in S3. This is how we keep networking,
# compute, and data layers in SEPARATE Terraform states while still letting
# them reference each other - a common pattern for larger infrastructure
# projects, avoiding one giant unwieldy state file.

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "jenkins_security_group_id" {
  value = aws_security_group.jenkins.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "availability_zones" {
  value = var.availability_zones
}
