# Ingress for external access to Vault (optional)
resource "kubernetes_ingress_v1" "vault" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "vault-ingress"
    namespace = kubernetes_namespace.vault.metadata[0].name
    
    labels = {
      "app.kubernetes.io/name"       = "vault"
      "app.kubernetes.io/instance"   = "vault"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    
    annotations = var.ingress_annotations
  }

  spec {
    ingress_class_name = var.ingress_class

    dynamic "tls" {
      for_each = var.vault_domain != "" ? [1] : []
      content {
        hosts       = [var.vault_domain]
        secret_name = "vault-tls-ingress"
      }
    }

    rule {
      host = var.vault_domain != "" ? var.vault_domain : null
      
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          
          backend {
            service {
              name = "vault-ui"
              port {
                number = 8200
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.vault]
}

# Service for external load balancer access (alternative to ingress) - DISABLED, using Helm service instead
resource "kubernetes_service" "vault_lb" {
  count = 0  # Disabled - using Helm chart LoadBalancer service instead

  metadata {
    name      = "vault-lb"
    namespace = kubernetes_namespace.vault.metadata[0].name
    
    labels = {
      "app.kubernetes.io/name"       = "vault"
      "app.kubernetes.io/instance"   = "vault"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      # Remove internal annotation to make it public
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol" = "TCP"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port" = "8200"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval" = "30"
    }
  }

  spec {
    type = "LoadBalancer"
    
    port {
      name        = "http"
      port        = 8200
      target_port = 8200
      protocol    = "TCP"
    }
    
    port {
      name        = "cluster"
      port        = 8201
      target_port = 8201
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "vault"
      "component" = "server"
    }
  }

  depends_on = [helm_release.vault]
}