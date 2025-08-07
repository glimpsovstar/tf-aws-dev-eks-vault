# Vault connection information
output "vault_namespace" {
  description = "Kubernetes namespace where Vault is deployed"
  value       = kubernetes_namespace.vault.metadata[0].name
}

output "vault_service_name" {
  description = "Name of the Vault service"
  value       = "vault-minimal"
}

output "vault_ui_service_name" {
  description = "Name of the Vault UI service"
  value       = "vault-minimal-ui"
}

output "vault_port" {
  description = "Port number for Vault API"
  value       = 8200
}

# EKS cluster information from remote state
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = data.terraform_remote_state.eks.outputs.eks_cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = data.aws_eks_cluster.eks.endpoint
}

output "cluster_region" {
  description = "AWS region where the cluster is deployed"
  value       = var.aws_region
}

# Vault configuration details
output "vault_kms_key_id" {
  description = "KMS key ID used for Vault auto-unseal"
  value       = data.terraform_remote_state.eks.outputs.vault_kms_key_id
}

output "vault_service_account_name" {
  description = "Name of the Vault service account"
  value       = "vault"
}

output "vault_service_account_role_arn" {
  description = "ARN of the IAM role for Vault service account"
  value       = data.terraform_remote_state.eks.outputs.vault_iam_role_arn
}

# Access information
output "vault_internal_url" {
  description = "Internal URL for accessing Vault within the cluster"
  value       = "https://vault.${kubernetes_namespace.vault.metadata[0].name}.svc.cluster.local:8200"
}

output "vault_ui_internal_url" {
  description = "Internal URL for accessing Vault UI within the cluster"
  value       = "https://vault-ui.${kubernetes_namespace.vault.metadata[0].name}.svc.cluster.local:8200"
}

output "vault_ingress_url" {
  description = "External URL for accessing Vault (if ingress is enabled)"
  value       = var.enable_ingress && var.vault_dns_name != "" ? "https://${var.vault_dns_name}" : null
}

output "vault_load_balancer_hostname" {
  description = "Load balancer hostname for external access (if LoadBalancer service is created)"
  value       = null  # LoadBalancer service not implemented in this configuration
}

# TLS certificate information
output "vault_ca_certificate" {
  description = "Vault CA certificate (base64 encoded)"
  value       = base64encode(tls_self_signed_cert.vault_ca.cert_pem)
  sensitive   = true
}

# Connection commands
output "kubectl_port_forward_command" {
  description = "Command to port-forward to Vault for local access"
  value       = "kubectl port-forward svc/vault-ui 8200:8200 -n ${kubernetes_namespace.vault.metadata[0].name}"
}

output "vault_init_command" {
  description = "Command to initialize Vault"
  value       = "kubectl exec vault-0 -n ${kubernetes_namespace.vault.metadata[0].name} -- vault operator init"
}

output "vault_status_command" {
  description = "Command to check Vault status"
  value       = "kubectl exec vault-0 -n ${kubernetes_namespace.vault.metadata[0].name} -- vault status"
}

# Helm release information
output "helm_release_name" {
  description = "Name of the Helm release for Vault"
  value       = helm_release.vault.name
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.vault.status
}

output "helm_release_version" {
  description = "Version of the Helm chart deployed"
  value       = helm_release.vault.version
}

#------------------------------------------------------------------------------
# DEBUG OUTPUTS
#------------------------------------------------------------------------------

output "debug_aws_caller_identity" {
  description = "Current AWS caller identity for debugging"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    arn        = data.aws_caller_identity.current.arn
    user_id    = data.aws_caller_identity.current.user_id
  }
}

output "debug_eks_cluster_info" {
  description = "EKS cluster information for debugging"
  value = {
    cluster_name = data.aws_eks_cluster.eks.name
    endpoint     = data.aws_eks_cluster.eks.endpoint
    version      = data.aws_eks_cluster.eks.version
    status       = data.aws_eks_cluster.eks.status
  }
  sensitive = true
}

# Public access information for Vault LoadBalancer
output "vault_public_url" {
  description = "Public URL to access Vault (once LoadBalancer is provisioned)"
  value       = "http://<VAULT_LOADBALANCER_URL>:8200"
}

output "vault_public_access_instructions" {
  description = "Instructions to get the public Vault URL"
  value = <<-EOT
    To get the public Vault URL after deployment:
    1. Run: kubectl get svc -n vault vault-minimal
    2. Look for EXTERNAL-IP column
    3. Access Vault at: http://<EXTERNAL-IP>:8200
    4. Login with token: myroot
    
    Or use this command to get the URL:
    kubectl get svc -n vault vault-minimal -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  EOT
}