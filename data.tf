data "terraform_remote_state" "eks" {
  backend = "remote"

  config = {
    organization = var.terraform_organization
    workspaces = {
      name = var.eks_workspace_name
    }
  }
}

data "aws_eks_cluster_auth" "eks_auth" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster_name
}

# Get VPC information from remote state outputs
data "aws_vpc" "cluster_vpc" {
  id = data.terraform_remote_state.eks.outputs.vpc_id
}

# Get subnets used by the EKS cluster from remote state
data "aws_subnets" "cluster_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.eks.outputs.vpc_id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# Get AWS region
data "aws_region" "current" {}

# Get AWS partition
data "aws_partition" "current" {}

# Get KMS key information from remote state
data "aws_kms_key" "vault" {
  key_id = data.terraform_remote_state.eks.outputs.vault_kms_key_id
}