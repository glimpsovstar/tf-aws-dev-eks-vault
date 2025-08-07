#!/bin/bash

# Script to configure kubectl access using the service account created by Terraform
echo "🔧 Configuring kubectl access to EKS cluster..."

CLUSTER_NAME="vault-demo-cluster"
REGION="ap-southeast-2"
SERVICE_ACCOUNT_NAME="admin-user"
NAMESPACE="kube-system"

echo "Getting service account token..."
TOKEN=$(kubectl get secret admin-user-token -n kube-system -o jsonpath='{.data.token}' | base64 -d)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get service account token"
    echo "Make sure Terraform has created the service account and secret"
    exit 1
fi

echo "✅ Got service account token"

# Update kubeconfig with the service account
echo "Configuring kubectl..."
kubectl config set-credentials admin-user --token="$TOKEN"
kubectl config set-context vault-admin --cluster=arn:aws:eks:${REGION}:521614675974:cluster/${CLUSTER_NAME} --user=admin-user
kubectl config use-context vault-admin

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
    echo "🚀 To access Vault UI, run:"
    echo "   kubectl port-forward -n vault svc/vault-minimal 8200:8200"
    echo "   Then open: http://localhost:8200"
    echo "   Token: myroot"
    
else
    echo "❌ Cluster access failed"
    echo "Check that the service account has been created by Terraform"
fi
