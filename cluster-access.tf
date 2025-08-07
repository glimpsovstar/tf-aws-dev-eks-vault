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

# Create a secret for the service account token (for Kubernetes 1.24+)
resource "kubernetes_secret" "admin_user_token" {
  metadata {
    name      = "admin-user-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.admin_user.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

# Output the service account information
output "admin_service_account" {
  description = "Service account information for cluster access"
  value = {
    name      = kubernetes_service_account.admin_user.metadata[0].name
    namespace = kubernetes_service_account.admin_user.metadata[0].namespace
  }
}

# Output instructions for accessing the cluster
output "kubectl_access_instructions" {
  description = "Instructions for accessing the cluster"
  value = <<-EOT
    To access the cluster locally, run:
    
    1. Get the token:
       kubectl get secret admin-user-token -n kube-system -o jsonpath='{.data.token}' | base64 -d
    
    2. Use the token with kubectl:
       kubectl config set-credentials admin-user --token=<TOKEN_FROM_STEP_1>
       kubectl config set-context vault-admin --cluster=arn:aws:eks:ap-southeast-2:521614675974:cluster/vault-demo-cluster --user=admin-user
       kubectl config use-context vault-admin
    
    3. Test access:
       kubectl get pods -n vault
  EOT
}
