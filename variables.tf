variable "aws_region" {
  description = "AWS region for the cluster"
  type        = string
  default     = "ap-southeast-2"
}

variable "vault_name" {
  description = "The name of the Vault service"
  type        = string
  default     = "djoo-demo-vault"
}

variable "vault_domain_name" {
  description = "The domain name for the Vault service"
  type        = string
  default     = "vault-poc.withdevo.dev"
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt notifications"
  type        = string
  default     = "glimpsovstar@gmail.com"
}

variable "vault_storage_size" {
  description = "Size of persistent storage for Vault"
  type        = string
  default     = "10Gi"
}

variable "kms_key_id" {
  description = "AWS KMS key ID for Vault Auto-Unseal"
  type        = string
  default     = "alias/my-vault-key"
}
