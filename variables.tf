variable "tls_email" {
  description = "Email for Let's Encrypt TLS certificates"
  type        = string
  default     = "glimpsovstar@gmail.com"
}

variable "vault_dns_name" {
  description = "Public DNS for Vault"
  type        = string
  default     = "vault-poc.withdevo.dev"
}
