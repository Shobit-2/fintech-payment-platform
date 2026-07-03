output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance - use this to SSH in and to reach the Jenkins UI"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_instance_id" {
  value = aws_instance.jenkins.id
}

output "jenkins_iam_role_name" {
  description = "IAM role name - future steps will attach more policies to this role by name"
  value       = aws_iam_role.jenkins.name
}

output "ssh_command" {
  description = "Ready-to-use SSH command (assumes your private key matches the public key you provided)"
  value       = "ssh -i <path-to-your-private-key> ubuntu@${aws_instance.jenkins.public_ip}"
}
