# Generate CA private key
resource "tls_private_key" "vault_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate CA certificate
resource "tls_self_signed_cert" "vault_ca" {
  private_key_pem = tls_private_key.vault_ca.private_key_pem

  subject {
    common_name  = "vault-ca"
    organization = "HashiCorp Vault"
  }

  validity_period_hours = 8760 # 1 year

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

# Generate Vault server private key
resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate certificate request for Vault server
resource "tls_cert_request" "vault" {
  private_key_pem = tls_private_key.vault.private_key_pem

  subject {
    common_name  = "vault.${var.vault_namespace}.svc.cluster.local"
    organization = "HashiCorp Vault"
  }

  dns_names = [
    "vault",
    "vault.${var.vault_namespace}",
    "vault.${var.vault_namespace}.svc",
    "vault.${var.vault_namespace}.svc.cluster.local",
    "vault-0.vault-internal",
    "vault-1.vault-internal", 
    "vault-2.vault-internal",
    "vault-0.vault-internal.${var.vault_namespace}.svc.cluster.local",
    "vault-1.vault-internal.${var.vault_namespace}.svc.cluster.local",
    "vault-2.vault-internal.${var.vault_namespace}.svc.cluster.local",
    "vault-active",
    "vault-active.${var.vault_namespace}.svc.cluster.local",
    "vault-standby",
    "vault-standby.${var.vault_namespace}.svc.cluster.local",
    "localhost"
  ]

  ip_addresses = [
    "127.0.0.1"
  ]
}

# Sign the certificate request with CA
resource "tls_locally_signed_cert" "vault" {
  cert_request_pem   = tls_cert_request.vault.cert_request_pem
  ca_private_key_pem = tls_private_key.vault_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.vault_ca.cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

# Create Kubernetes secret with TLS certificates
resource "kubernetes_secret" "vault_tls" {
  metadata {
    name      = "vault-tls"
    namespace = kubernetes_namespace.vault.metadata[0].name
    
    labels = {
      "app.kubernetes.io/name"       = "vault"
      "app.kubernetes.io/instance"   = "vault"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = "${tls_locally_signed_cert.vault.cert_pem}${tls_self_signed_cert.vault_ca.cert_pem}"
    "tls.key" = tls_private_key.vault.private_key_pem
    "ca.crt"  = tls_self_signed_cert.vault_ca.cert_pem
  }

  depends_on = [kubernetes_namespace.vault]
}