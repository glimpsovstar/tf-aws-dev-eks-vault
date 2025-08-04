variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vault_namespace" {
  description = "Kubernetes namespace for Vault"
  type        = string
  default     = "vault"
}

variable "vault_replicas" {
  description = "Number of Vault replicas for HA"
  type        = number
  default     = 3
}

variable "enable_vault_ui" {
  description = "Enable Vault web UI"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable ingress for external access"
  type        = bool
  default     = false
}

variable "ingress_class" {
  description = "Ingress class name"
  type        = string
  default     = "alb"
}

variable "ingress_annotations" {
  description = "Annotations for the ingress resource"
  type        = map(string)
  default = {
    "kubernetes.io/ingress.class"                    = "alb"
    "alb.ingress.kubernetes.io/scheme"              = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"         = "ip"
    "alb.ingress.kubernetes.io/backend-protocol"    = "HTTP"
    "alb.ingress.kubernetes.io/healthcheck-path"    = "/v1/sys/health"
    "alb.ingress.kubernetes.io/healthcheck-port"    = "8200"
    "alb.ingress.kubernetes.io/listen-ports"        = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
    "alb.ingress.kubernetes.io/ssl-redirect"        = "443"
  }
}

variable "vault_domain" {
  description = "Domain name for Vault ingress (required if enable_ingress is true)"
  type        = string
  default     = ""
}

variable "storage_class" {
  description = "Storage class for Vault persistent volumes"
  type        = string
  default     = "vault-storage"
}

variable "storage_size" {
  description = "Size of persistent volumes for Vault"
  type        = string
  default     = "10Gi"
}

variable "vault_image_tag" {
  description = "Vault image tag"
  type        = string
  default     = "1.15.4"
}

variable "vault_resources" {
  description = "Resource requests and limits for Vault pods"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "256Mi"
      cpu    = "250m"
    }
    limits = {
      memory = "1Gi"
      cpu    = "500m"
    }
  }
}

variable "enable_audit_log" {
  description = "Enable audit logging"
  type        = bool
  default     = true
}

variable "enable_metrics" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "metrics_path" {
  description = "Path for Prometheus metrics"
  type        = string
  default     = "/v1/sys/metrics"
}

variable "vault_log_level" {
  description = "Vault log level"
  type        = string
  default     = "INFO"
  
  validation {
    condition     = contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR"], var.vault_log_level)
    error_message = "Log level must be one of: TRACE, DEBUG, INFO, WARN, ERROR."
  }
}

variable "additional_helm_values" {
  description = "Additional Helm values to pass to the Vault chart"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Terraform Cloud workspace configuration
variable "eks_workspace_name" {
  description = "Name of the EKS Terraform Cloud workspace (can be overridden)"
  type        = string
  default     = "tf-aws-dev-eks"
}

variable "terraform_organization" {
  description = "Terraform Cloud organization name (can be overridden via TF_CLOUD_ORGANIZATION)"
  type        = string
  default     = "djoo-hashicorp"
}

# TLS Configuration (for certificate generation)
variable "tls_email" {
  description = "Email address for Let's Encrypt TLS certificates"
  type        = string
  default     = ""
}

variable "vault_dns_name" {
  description = "DNS name for Vault ingress (if ingress is enabled)"
  type        = string
  default     = ""
}