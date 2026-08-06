# Imports YOUR existing public key into AWS so it can be attached to the
# instance for SSH login. Terraform never sees or stores your private key.
resource "aws_key_pair" "jenkins" {
  key_name   = "${var.project_name}-jenkins-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  lifecycle {
    # Prevents Terraform from replacing this instance every time a newer
    # Ubuntu AMI is published upstream. The AMI lookup (data.aws_ami.ubuntu)
    # is still useful for the FIRST creation of this instance, but once
    # it's running - especially with hours of manual setup on it (Jenkins,
    # Docker, Trivy, Maven, JDKs) - we never want a routine `terraform plan`
    # to silently propose destroying and recreating it just because a new
    # AMI exists. Applying OS patches to a running instance should be a
    # deliberate, separate action (apt upgrade over SSH), not an accidental
    # side effect of re-running Terraform.
    ignore_changes = [ami]
  }

  # First public subnet from the networking layer's output. Jenkins needs a
  # public IP (below) to be reachable, hence a public subnet - reachability
  # is controlled by the security group, not subnet choice, but public
  # subnets are also where instances CAN receive a public IP at all.
  subnet_id = data.terraform_remote_state.networking.outputs.public_subnet_ids[0]

  vpc_security_group_ids = [
    data.terraform_remote_state.networking.outputs.jenkins_security_group_id
  ]

  key_name                    = aws_key_pair.jenkins.key_name
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  root_block_device {
    volume_size           = var.root_volume_size_gb
    volume_type            = "gp3"
    encrypted              = true
    delete_on_termination  = true
  }

  # Deliberately NO user_data here - per your choice, everything (Jenkins,
  # Docker, kubectl, AWS CLI) gets installed manually via SSH so each step
  # is something you've actually typed and understood. We'll circle back
  # and codify this into a user-data/JCasC script AFTER you've seen it work
  # manually, exactly as discussed earlier in the course.

  tags = {
    Name = "${var.project_name}-jenkins"
  }
}
