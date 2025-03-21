terraform {
  cloud {
    organization = "djoo-hashicorp"
    workspaces {
      name = "tf-aws-dev-eks-vault"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "eks" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  token                  = data.aws_eks_cluster_auth.eks_auth.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
}

