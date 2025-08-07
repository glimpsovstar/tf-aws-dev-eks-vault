#!/bin/bash

# Script to access Vault using AWS CLI with temporary access
echo "🔧 Attempting to access Vault through EKS..."

CLUSTER_NAME="vault-demo-cluster"
REGION="ap-southeast-2"

echo "Current AWS identity:"
aws sts get-caller-identity

echo ""
echo "Attempting to update kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME --alias vault-cluster

if [ $? -ne 0 ]; then
    echo "❌ Failed to update kubeconfig."
    echo ""
    echo "🔧 SOLUTION: Add your AWS role to the EKS cluster auth."
    echo "In your tf-aws-dev-eks workspace, modify main.tf:"
    echo ""
    echo "Add this to the module \"eks\" block:"
    echo "  access_entries = {"
    echo "    david_joo_access = {"
    echo "      kubernetes_groups = [\"system:masters\"]"
    echo "      principal_arn     = \"arn:aws:iam::521614675974:role/aws_david.joo_test-developer\""
    echo "      type             = \"STANDARD\""
    echo "    }"
    echo "  }"
    echo ""
    echo "Then run terraform apply in the tf-aws-dev-eks workspace."
    exit 1
fi

echo "✅ kubectl configured!"

# Test access
echo "Testing cluster access..."
kubectl config use-context vault-cluster

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
    echo "1. Run: kubectl port-forward -n vault svc/vault-minimal 8200:8200"
    echo "2. Open: http://localhost:8200"
    echo "3. Login with token: myroot"
    echo ""
    echo "🔧 Or use Vault CLI:"
    echo "export VAULT_ADDR=http://localhost:8200"
    echo "export VAULT_TOKEN=myroot"
    echo "vault status"
    
else
    echo "❌ Still no cluster access. Your AWS role needs to be added to the EKS cluster."
    echo "Please add your role to tf-aws-dev-eks workspace as shown above."
fi
