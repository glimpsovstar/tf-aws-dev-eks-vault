# Debug resource to check Vault status from Terraform Cloud
resource "null_resource" "vault_status_check" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "=== VAULT STATUS CHECK FROM TERRAFORM CLOUD ==="
      
      # Check pods
      echo "Checking Vault pods..."
      kubectl get pods -n vault -o wide || echo "Failed to get pods"
      
      # Check services
      echo "Checking Vault services..."
      kubectl get svc -n vault || echo "Failed to get services"
      
      # Check if Vault is responding
      echo "Testing Vault connectivity..."
      kubectl exec -n vault deployment/vault-minimal -- wget -O- -q --timeout=5 http://localhost:8200/v1/sys/health || echo "Vault health check failed"
      
      # Get pod logs
      echo "Checking Vault logs..."
      kubectl logs -n vault -l app.kubernetes.io/name=vault --tail=20 || echo "Failed to get logs"
      
      echo "=== END VAULT STATUS CHECK ==="
    EOT
  }
  
  depends_on = [helm_release.vault]
  
  triggers = {
    always_run = timestamp()
  }
}
