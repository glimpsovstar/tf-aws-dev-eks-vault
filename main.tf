# HashiCorp Vault on EKS - Main Configuration
# This file serves as the primary entry point for the Vault deployment

locals {
  # Common tags applied to all resources
  common_tags = merge(var.tags, {
    Project     = "vault-eks"
    Environment = var.environment
    ManagedBy   = "terraform"
    Workspace   = "tf-aws-dev-eks-vault"
  })

  # Vault configuration variables from remote state
  vault_cluster_name = data.terraform_remote_state.eks.outputs.eks_cluster_name
  vault_kms_key_id   = data.terraform_remote_state.eks.outputs.vault_kms_key_id
  vault_sa_role_arn  = data.terraform_remote_state.eks.outputs.vault_iam_role_arn
  
  # Network configuration from EKS
  vpc_id             = data.terraform_remote_state.eks.outputs.vpc_id
}

#------------------------------------------------------------------------------
# MAIN VAULT DEPLOYMENT
#------------------------------------------------------------------------------

# Note: The actual Vault deployment resources are organized in separate files:
# - vault-namespace.tf     : Kubernetes namespace
# - vault-rbac.tf         : Service accounts, roles, and bindings  
# - vault-tls.tf          : TLS certificate generation
# - vault-helm.tf         : Helm chart deployment
# - vault-ingress.tf      : Ingress configuration (optional)

# This main.tf file serves as the entry point and contains shared locals
# that are used across the other resource files.

#------------------------------------------------------------------------------
# VALIDATION AND PREREQUISITES
#------------------------------------------------------------------------------

# Validate that we can access the remote state
resource "null_resource" "validate_remote_state" {
  provisioner "local-exec" {
    command = "echo 'Remote state validation: EKS cluster ${local.vault_cluster_name} in region ${var.aws_region}'"
  }
  
  triggers = {
    cluster_name = local.vault_cluster_name
    kms_key_id   = local.vault_kms_key_id
    region       = var.aws_region
  }
}

# Validate AWS credentials and EKS access
resource "null_resource" "validate_eks_access" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Current AWS identity: $(aws sts get-caller-identity --query 'Arn' --output text)"
      echo "Testing EKS cluster access..."
      aws eks describe-cluster --name "${local.vault_cluster_name}" --region "${var.aws_region}" --query 'cluster.status' --output text
    EOT
  }
  
  triggers = {
    cluster_name = local.vault_cluster_name
    region       = var.aws_region
  }
}

#------------------------------------------------------------------------------
# OUTPUTS SUMMARY
#------------------------------------------------------------------------------

# Key information for post-deployment
output "deployment_summary" {
  description = "Summary of the Vault deployment"
  value = {
    cluster_name    = local.vault_cluster_name
    vault_namespace = var.vault_namespace
    vault_replicas  = var.vault_replicas
    kms_key_id      = local.vault_kms_key_id
    region          = var.aws_region
    ui_enabled      = var.enable_vault_ui
    ingress_enabled = var.enable_ingress
  }
}