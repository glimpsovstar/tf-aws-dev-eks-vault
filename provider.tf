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

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint
  token                  = data.aws_eks_cluster_auth.eks_auth.token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_certificate_authority)
}
