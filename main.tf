resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.vault_name
  }
}

resource "kubernetes_stateful_set" "vault" {
  metadata {
    name      = var.vault_name
    namespace = kubernetes_namespace.vault.metadata.0.name
  }

  spec {
    service_name = "vault"
    replicas     = 2

    selector {
      match_labels = {
        app = var.vault_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.vault_name
        }
      }

      spec {
        container {
          name  = "vault"
          image = "hashicorp/vault:latest"

          args = ["server"]

          volume_mount {
            name       = "vault-tls"
            mount_path = "/etc/tls"
            read_only  = true
          }

          volume_mount {
            name       = "vault-storage"
            mount_path = "/vault/data"
          }

          port {
            container_port = 8200
          }

          env {
            name  = "VAULT_ADDR"
            value = "https://${var.vault_domain_name}"
          }

          env {
            name  = "VAULT_CLUSTER_ADDR"
            value = "https://${var.vault_domain_name}:8200"
          }

          env {
            name  = "VAULT_SEAL_TYPE"
            value = "awskms"
          }

          env {
            name  = "VAULT_AWSKMS_SEAL_KEY_ID"
            value = var.kms_key_id
          }
        }

        volume {
          name = "vault-tls"
          secret {
            secret_name = "vault-tls"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "vault-storage"
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.vault_storage_size
          }
        }
      }
    }
  }
}



resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.2"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "extraArgs[0]"
    value = "--enable-certificate-owner-ref=true"
  }
}

resource "kubernetes_manifest" "letsencrypt_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email  = var.letsencrypt_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  }
}

resource "kubernetes_manifest" "vault_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "vault-tls"
      namespace = kubernetes_namespace.vault.metadata.0.name
    }
    spec = {
      secretName  = "vault-tls"
      duration    = "90d"
      renewBefore = "30d"
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
      dnsNames = [var.vault_domain_name]
    }
  }
}

resource "kubernetes_secret" "vault_root_token" {
  metadata {
    name      = "vault-root-token"
    namespace = kubernetes_namespace.vault.metadata.0.name
  }

  type = "Opaque"

  data = {
    root_token = "REPLACE_WITH_GENERATED_TOKEN"
  }
}

resource "aws_lb" "vault_nlb" {
  name               = "${var.vault_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.terraform_remote_state.eks.outputs.subnet_ids
}

resource "aws_lb_target_group" "vault" {
  name        = "${var.vault_name}-tg"
  port        = 8200
  protocol    = "TCP"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "vault_https" {
  load_balancer_arn = aws_lb.vault_nlb.arn
  port              = 8200
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }
}

resource "kubernetes_persistent_volume_claim" "vault_storage" {
  metadata {
    name      = "${var.vault_name}-storage"
    namespace = kubernetes_namespace.vault.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.vault_storage_size
      }
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = data.terraform_remote_state.eks.outputs.eks_iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = data.terraform_remote_state.eks.outputs.eks_iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = data.terraform_remote_state.eks.outputs.eks_iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

