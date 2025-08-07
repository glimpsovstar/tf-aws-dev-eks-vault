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
      
      # Check endpoints
      echo "Checking service endpoints..."
      kubectl get endpoints -n vault || echo "Failed to get endpoints"
      
      # Check deployment
      echo "Checking deployment..."
      kubectl get deployment -n vault || echo "No deployments found"
      
      # Get events
      echo "Recent events in vault namespace..."
      kubectl get events -n vault --sort-by='.lastTimestamp' | tail -10 || echo "Failed to get events"
      
      # Get pod logs if pods exist
      echo "Checking for pod logs..."
      PODS=$(kubectl get pods -n vault -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
      if [ ! -z "$PODS" ]; then
        for POD in $PODS; do
          echo "=== Logs for $POD ==="
          kubectl logs $POD -n vault --tail=30 || echo "Failed to get logs for $POD"
        done
      else
        echo "No pods found in vault namespace"
      fi
      
      # Test service connectivity from within cluster
      echo "Testing internal service connectivity..."
      kubectl run vault-test --image=curlimages/curl:latest --rm -i --restart=Never -- curl -s -m 10 http://vault-minimal.vault.svc.cluster.local:8200/v1/sys/health || echo "Service connectivity test failed"
      
      echo "=== END VAULT STATUS CHECK ==="
    EOT
  }
  
  depends_on = [
    helm_release.vault
  ]
  
  triggers = {
    always_run = timestamp()
  }
}
