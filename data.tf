data "terraform_remote_state" "eks" {
  backend = "remote"

  config = {
    organization = "djoo-hashicorp"
    workspaces = {
      name = "tf-aws-dev-eks"
    }
  }
}

data "aws_eks_cluster_auth" "eks_auth" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster_name
}
