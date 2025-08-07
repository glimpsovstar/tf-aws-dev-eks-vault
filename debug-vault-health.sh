#!/bin/bash

echo "=== Debugging Vault Health Issues ==="
echo "Date: $(date)"
echo

# First, let's check if we can access the cluster at all
echo "1. Checking EKS cluster access..."
kubectl get nodes 2>/dev/null || echo "❌ Cannot access EKS cluster - authentication issue"
echo

# Check if vault namespace exists
echo "2. Checking vault namespace..."
kubectl get namespace vault 2>/dev/null || echo "❌ Vault namespace not found"
echo

# Check vault pods
echo "3. Checking vault pods..."
kubectl get pods -n vault -o wide 2>/dev/null || echo "❌ Cannot get vault pods"
echo

# Check vault service
echo "4. Checking vault service..."
kubectl get svc -n vault 2>/dev/null || echo "❌ Cannot get vault service"
echo

# If we can access, let's check the service in detail
echo "5. Describing vault service..."
kubectl describe svc -n vault 2>/dev/null || echo "❌ Cannot describe vault service"
echo

# Check if vault is responding internally
echo "6. Testing vault health endpoint from within cluster..."
POD_NAME=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$POD_NAME" ]; then
    echo "Found pod: $POD_NAME"
    echo "Testing /v1/sys/health endpoint..."
    kubectl exec -n vault "$POD_NAME" -- curl -s http://localhost:8200/v1/sys/health || echo "❌ Health check failed"
    echo
    echo "Testing basic connectivity..."
    kubectl exec -n vault "$POD_NAME" -- curl -s http://localhost:8200/v1/sys/init || echo "❌ Basic connectivity failed"
else
    echo "❌ No vault pods found"
fi

echo
echo "=== End Debug ==="
