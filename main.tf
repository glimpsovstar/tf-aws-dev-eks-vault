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
        app = "vault"
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
          image = "hashicorp/vault:1.14"
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
          volume_mount {
            mount_path = "/vault/data"
            name       = "vault-storage"
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

  data = {
    root_token = "REPLACE_WITH_GENERATED_TOKEN"
  }

  type = "Opaque"
}


