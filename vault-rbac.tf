# Service accounts are now managed by Helm
# The Helm chart will create these service accounts with proper labels and annotations

# Service account for Vault - managed by Helm
# resource "kubernetes_service_account" "vault" {
#   metadata {
#     name      = "vault"
#     namespace = kubernetes_namespace.vault.metadata[0].name
#     
#     labels = {
#       "app.kubernetes.io/name"       = "vault"
#       "app.kubernetes.io/instance"   = "vault"
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#     
#     annotations = {
#       "eks.amazonaws.com/role-arn" = local.vault_sa_role_arn
#     }
#   }
#   
#   automount_service_account_token = true
# }

# Service account for Vault Agent Injector - managed by Helm
# resource "kubernetes_service_account" "vault_agent_injector" {
#   metadata {
#     name      = "vault-agent-injector"
#     namespace = kubernetes_namespace.vault.metadata[0].name
#     
#     labels = {
#       "app.kubernetes.io/name"       = "vault-agent-injector"
#       "app.kubernetes.io/instance"   = "vault"
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }
# }

# RBAC resources are now managed by Helm
# The Helm chart will create appropriate cluster roles and bindings with proper labels

# ClusterRole for Vault - managed by Helm
# resource "kubernetes_cluster_role" "vault" {
#   metadata {
#     name = "vault-server"
#     
#     labels = {
#       "app.kubernetes.io/name"       = "vault"
#       "app.kubernetes.io/instance"   = "vault"
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }

#   rule {
#     api_groups = [""]
#     resources  = ["pods"]
#     verbs      = ["get", "watch", "list", "update", "patch"]
#   }
  
#   rule {
#     api_groups = [""]
#     resources  = ["pods/exec"]
#     verbs      = ["create"]
#   }
  
#   rule {
#     api_groups = [""]
#     resources  = ["endpoints"]
#     verbs      = ["get", "watch", "list"]
#   }
  
#   rule {
#     api_groups = [""]
#     resources  = ["services"]
#     verbs      = ["get", "watch", "list"]
#   }
# }

# ClusterRoleBinding for Vault - managed by Helm
# resource "kubernetes_cluster_role_binding" "vault" {
#   metadata {
#     name = "vault-server-binding"
#     
#     labels = {
#       "app.kubernetes.io/name"       = "vault"
#       "app.kubernetes.io/instance"   = "vault"
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.vault.metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = "vault"
#     namespace = kubernetes_namespace.vault.metadata[0].name
#   }
# }

# ClusterRole for Vault Agent Injector - managed by Helm
# resource "kubernetes_cluster_role" "vault_agent_injector" {
#   metadata {
#     name = "vault-agent-injector"
#     
#     labels = {
#       "app.kubernetes.io/name"       = "vault-agent-injector"
#       "app.kubernetes.io/instance"   = "vault"
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }

#   rule {
#     api_groups = ["admissionregistration.k8s.io"]
#     resources  = ["mutatingwebhookconfigurations"]
#     verbs      = ["get", "list", "watch", "patch"]
#   }
# }

# ClusterRoleBinding for Vault Agent Injector - managed by Helm
# resource "kubernetes_cluster_role_binding" "vault_agent_injector" {
#   metadata {
#     name = "vault-agent-injector-binding"
#     
#     labels = {
#       "app.kubernetes.io/name"       = "vault-agent-injector"
#       "app.kubernetes.io/instance"   = "vault"
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.vault_agent_injector.metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = "vault-agent-injector"
#     namespace = kubernetes_namespace.vault.metadata[0].name
#   }
# }

# All RBAC resources are managed by Helm to avoid ownership conflicts