#!/bin/bash

# Test script for minimal Vault deployment
# Run this after Terraform deployment to verify Vault is working

NAMESPACE=${VAULT_NAMESPACE:-vault}
SERVICE_NAME=${VAULT_SERVICE_NAME:-vault-minimal}

echo "=== Testing Minimal Vault Deployment ==="

# Check if pod is running
echo "Checking Vault pod status..."
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=vault

# Check if service exists
echo "Checking Vault service..."
kubectl get svc -n $NAMESPACE $SERVICE_NAME

# Port forward and test basic connectivity
echo "Testing Vault connectivity..."
kubectl port-forward -n $NAMESPACE svc/$SERVICE_NAME 8200:8200 &
PORT_FORWARD_PID=$!

# Wait a bit for port-forward to establish
sleep 5

# Test Vault status
echo "Testing Vault API..."
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

# Check Vault status
curl -s http://localhost:8200/v1/sys/health || echo "Health check failed"

# List auth methods
curl -s -H "X-Vault-Token: myroot" http://localhost:8200/v1/sys/auth || echo "Auth methods check failed"

# Cleanup
kill $PORT_FORWARD_PID 2>/dev/null

echo "=== Test completed ==="
