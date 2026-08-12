data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "fintech-payment-platform-tfstate"
    key    = "fintech/networking/terraform.tfstate"
    region = var.aws_region
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access  = true
  endpoint_private_access = true

  endpoint_public_access_cidrs = var.cluster_public_access_cidrs

  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id

  subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids

  enable_irsa = true

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }

    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    main = {
      name = "${var.project_name}-nodes"

      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids

      capacity_type = "ON_DEMAND"

      ami_type = "AL2023_x86_64_STANDARD"

      disk_size = 30

      labels = {
        Environment = var.environment
        Workload    = "general"
      }
    }
  }

  tags = {
    Name = var.cluster_name
  }
}