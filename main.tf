terraform {
  cloud {
    organization = "djoo-hashicorp"
    workspaces {
      name = "tf-eks-vault"
    }
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint
  token                  = data.aws_eks_cluster_auth.eks_auth.token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_certificate_authority)
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_stateful_set" "vault" {
  metadata {
    name      = "vault"
    namespace = "vault"
  }

  spec {
    service_name = "vault"
    replicas     = 2

    selector {
      match_labels = {
        app = "vault"
      }
    }

    template {
      metadata {
        labels = {
          app = "vault"
        }
      }

      spec {
        container {
          name  = "vault"
          image = "hashicorp/vault:1.14"
          port {
            container_port = 8200
          }
          env {
            name  = "VAULT_ADDR"
            value = "https://vault-poc.withdevo.dev"
          }
        }
      }
    }
  }
}

