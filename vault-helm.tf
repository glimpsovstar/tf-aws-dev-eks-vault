# Add HashiCorp Helm repository
resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.27.0"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  
  wait             = true
  wait_for_jobs    = false
  timeout          = 1200
  create_namespace = false
  
  # Force upgrade if needed
  force_update = true
  recreate_pods = true
  
  # Core Vault configuration
  set {
    name  = "global.enabled"
    value = "true"
  }
  
  set {
    name  = "global.tlsDisable"
    value = "true"
  }
  
  # Injector configuration
  set {
    name  = "injector.enabled"
    value = "true"
  }
  
  set {
    name  = "injector.replicas"
    value = "1"
  }
  
  set {
    name  = "injector.port"
    value = "8080"
  }
  
  set {
    name  = "injector.metrics.enabled"
    value = var.enable_metrics
  }
  
  set {
    name  = "injector.serviceAccount.create"
    value = "true"
  }
  
  set {
    name  = "injector.serviceAccount.name"
    value = "vault-agent-injector"
  }
  
  # Server configuration
  set {
    name  = "server.enabled"
    value = "true"
  }
  
  set {
    name  = "server.image.tag"
    value = var.vault_image_tag
  }
  
  set {
    name  = "server.logLevel"
    value = var.vault_log_level
  }
  
  # High Availability configuration - temporarily disabled for initial deployment
  set {
    name  = "server.ha.enabled"
    value = "false"
  }
  
  set {
    name  = "server.ha.replicas"
    value = "1"
  }
  
  # Raft integrated storage - disabled for single-node deployment
  set {
    name  = "server.ha.raft.enabled"
    value = "false"
  }
  
  set {
    name  = "server.ha.raft.setNodeId"
    value = "false"
  }
  
  # Use file storage for single-node deployment
  set {
    name  = "server.dataStorage.enabled"
    value = "true"
  }
  
  set {
    name  = "server.dataStorage.size"
    value = "10Gi"
  }
  
  set {
    name  = "server.dataStorage.storageClass"
    value = "gp2"
  }
  
  # Service account
  set {
    name  = "server.serviceAccount.create"
    value = "true"
  }
  
  set {
    name  = "server.serviceAccount.name"
    value = "vault"
  }
  
  set {
    name  = "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = local.vault_sa_role_arn
  }
  
  # Resources
  set {
    name  = "server.resources.requests.memory"
    value = var.vault_resources.requests.memory
  }
  
  set {
    name  = "server.resources.requests.cpu"
    value = var.vault_resources.requests.cpu
  }
  
  set {
    name  = "server.resources.limits.memory"
    value = var.vault_resources.limits.memory
  }
  
  set {
    name  = "server.resources.limits.cpu"
    value = var.vault_resources.limits.cpu
  }
  
  # Data storage
  set {
    name  = "server.dataStorage.enabled"
    value = "true"
  }
  
  set {
    name  = "server.dataStorage.size"
    value = var.storage_size
  }
  
  set {
    name  = "server.dataStorage.storageClass"
    value = var.storage_class
  }
  
  set {
    name  = "server.dataStorage.accessMode"
    value = "ReadWriteOnce"
  }
  
  # Audit storage
  set {
    name  = "server.auditStorage.enabled"
    value = var.enable_audit_log
  }
  
  set {
    name  = "server.auditStorage.size"
    value = "10Gi"
  }
  
  set {
    name  = "server.auditStorage.storageClass"
    value = var.storage_class
  }
  
  # Affinity and tolerations
  set {
    name  = "server.affinity"
    value = ""
  }
  
  # Standalone configuration disabled (using HA)
  set {
    name  = "server.standalone.enabled"
    value = "false"
  }
  
  # UI configuration
  set {
    name  = "ui.enabled"
    value = var.enable_vault_ui
  }
  
  set {
    name  = "ui.serviceType"
    value = "ClusterIP"
  }
  
  # CSI Provider (disabled for now)
  set {
    name  = "csi.enabled"
    value = "false"
  }
  
  # Basic standalone server configuration for initial deployment
  set {
    name  = "server.standalone.enabled"
    value = "true"
  }
  
  set {
    name  = "server.standalone.config"
    value = <<-EOT
      ui = true
      
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      
      storage "file" {
        path = "/vault/data"
      }
      
      seal "awskms" {
        region     = "${var.aws_region}"
        kms_key_id = "${data.terraform_remote_state.eks.outputs.vault_kms_key_id}"
      }
    EOT
  }
  
  # Server configuration via values - temporarily disabled for troubleshooting
  # values = [
  #   templatefile("${path.module}/values/vault-values.yaml", {
  #     kms_key_id          = data.terraform_remote_state.eks.outputs.vault_kms_key_id
  #     region              = var.aws_region
  #     enable_audit_log    = var.enable_audit_log
  #     enable_metrics      = var.enable_metrics
  #     enable_vault_ui     = var.enable_vault_ui
  #     metrics_path        = var.metrics_path
  #     log_level           = var.vault_log_level
  #     namespace           = var.vault_namespace
  #     service_account     = "vault"
  #     cluster_name        = data.terraform_remote_state.eks.outputs.eks_cluster_name
  #   })
  # ]
  
  depends_on = [
    kubernetes_namespace.vault
  ]
}