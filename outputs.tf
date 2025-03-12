output "vault_namespace" {
  description = "Kubernetes namespace for Vault"
  value       = kubernetes_namespace.vault.metadata.0.name
}

output "vault_storage_pvc" {
  description = "Persistent Volume Claim name for Vault storage"
  value       = kubernetes_persistent_volume_claim.vault_storage.metadata.0.name
}

output "vault_tls_secret" {
  description = "Secret name containing Vault's TLS certificate"
  value       = kubernetes_manifest.vault_certificate.manifest.spec.secretName
}

output "vault_root_token_secret" {
  description = "Kubernetes secret storing Vault root token"
  value       = kubernetes_secret.vault_root_token.metadata.0.name
}

