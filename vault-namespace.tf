# Create namespace for Vault
resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.vault_namespace
    
    labels = {
      name                                 = var.vault_namespace
      "app.kubernetes.io/name"            = "vault"
      "app.kubernetes.io/instance"        = "vault"
      "app.kubernetes.io/version"         = var.vault_image_tag
      "app.kubernetes.io/managed-by"      = "terraform"
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
    
    annotations = {
      "terraform.io/managed" = "true"
    }
  }
}