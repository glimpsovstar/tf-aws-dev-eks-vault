#!/bin/bash

# Simple script to access Vault using AWS CLI for EKS auth
echo "🔧 Setting up kubectl access to EKS cluster..."

CLUSTER_NAME="vault-demo-cluster"
REGION="ap-southeast-2"

echo "Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

if [ $? -ne 0 ]; then
    echo "❌ Failed to update kubeconfig. Make sure you have:"
    echo "  1. AWS CLI configured with proper credentials"
    echo "  2. EKS permissions to access the cluster"
    exit 1
fi

echo "✅ kubectl configured!"

# Test access
echo "Testing cluster access..."
if kubectl get nodes > /dev/null 2>&1; then
    echo "✅ Cluster access working!"
    
    # Check Vault status
    echo ""
    echo "🔍 Checking Vault deployment..."
    echo "Vault pods:"
    kubectl get pods -n vault
    
    echo ""
    echo "Vault services:"
    kubectl get svc -n vault
    
    echo ""
    echo "🚀 To access Vault UI:"
    echo "1. Port-forward: kubectl port-forward -n vault svc/vault-minimal 8200:8200"
    echo "2. Open: http://localhost:8200"
    echo "3. Login with token: myroot"
    echo ""
    echo "🔧 To access Vault CLI:"
    echo "export VAULT_ADDR=http://localhost:8200"
    echo "export VAULT_TOKEN=myroot"
    echo "vault status"
    
else
    echo "❌ Cluster access failed"
    echo "Check your AWS credentials and EKS permissions"
fi
