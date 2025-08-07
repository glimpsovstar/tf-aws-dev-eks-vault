# Create a service account for cluster access
resource "kubernetes_service_account" "admin_user" {
  metadata {
    name      = "admin-user"
    namespace = "kube-system"
  }
}

# Create cluster role binding for admin access
resource "kubernetes_cluster_role_binding" "admin_user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.admin_user.metadata[0].name
    namespace = kubernetes_service_account.admin_user.metadata[0].namespace
  }
}

# Get the service account token
data "kubernetes_secret" "admin_user_token" {
  metadata {
    name      = kubernetes_service_account.admin_user.default_secret_name
    namespace = "kube-system"
  }
  
  depends_on = [kubernetes_service_account.admin_user]
}

# Output the token for manual kubectl configuration
output "admin_token" {
  description = "Service account token for cluster access"
  value       = data.kubernetes_secret.admin_user_token.data.token
  sensitive   = true
}
