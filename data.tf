data "terraform_remote_state" "eks" {
  backend = "remote"

  config = {
    organization = "djoo-hashicorp"
    workspaces = {
      name = "tf-aws-eks"
    }
  }
}

