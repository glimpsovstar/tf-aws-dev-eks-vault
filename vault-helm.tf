# MINIMAL Vault Deployment for Testing
# This is a stripped-down configuration to get Vault working first

resource "helm_release" "vault" {
  name       = "vault-minimal"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.27.0"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  
  # Minimal deployment settings with debugging
  wait             = true   # Actually wait to see what's failing
  wait_for_jobs    = false  # Don't wait for jobs
  timeout          = 600    # 10 minutes for debugging
  create_namespace = false
  cleanup_on_fail  = false  # Keep failed resources for debugging
  
  # DEVELOPMENT MODE - In-memory storage, no persistence
  set {
    name  = "server.dev.enabled"
    value = "true"
  }
  
  set {
    name  = "server.dev.devRootToken"
    value = "myroot"
  }
  
  # Disable complex features
  set {
    name  = "injector.enabled"
    value = "false"
  }
  
  set {
    name  = "ui.enabled"
    value = "true"
  }
  
  set {
    name  = "server.ha.enabled"
    value = "false"
  }
  
  set {
    name  = "server.dataStorage.enabled"
    value = "false"
  }
  
  # Minimal resources
  set {
    name  = "server.resources.requests.memory"
    value = "128Mi"
  }
  
  set {
    name  = "server.resources.requests.cpu"
    value = "50m"
  }
  
  # No TLS
  set {
    name  = "global.tlsDisable"
    value = "true"
  }

  # Expose Vault via LoadBalancer for public access 
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.service.port"
    value = "8200"
  }

  # Configure basic health checks
  set {
    name  = "server.readinessProbe.enabled"
    value = "true"
  }

  set {
    name  = "server.livenessProbe.enabled"
    value = "true"
  }

  # Expose UI through the main server service
  set {
    name  = "ui.externalPort"
    value = "8200"
  }

  depends_on = [
    kubernetes_namespace.vault,
    null_resource.validate_helm_prerequisites
  ]
}
