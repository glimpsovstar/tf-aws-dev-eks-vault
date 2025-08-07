#!/bin/bash

# Script to get Vault's public LoadBalancer URL
echo "🔍 Getting Vault's public LoadBalancer URL..."

CLUSTER_NAME="vault-demo-cluster"
REGION="ap-southeast-2"

echo "Configuring kubectl..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME --alias vault-cluster 2>/dev/null

echo "Checking Vault LoadBalancer service..."
kubectl config use-context vault-cluster 2>/dev/null

# Check if we can access the cluster
if ! kubectl get nodes > /dev/null 2>&1; then
    echo "❌ Cannot access EKS cluster. You need kubectl access first."
    echo "💡 Alternative: Check Terraform Cloud outputs for the LoadBalancer URL"
    echo "   Or apply the EKS access fix in tf-aws-dev-eks workspace"
    exit 1
fi

echo "✅ Cluster access working!"
echo ""

# Get the LoadBalancer service
echo "Vault LoadBalancer service status:"
kubectl get svc -n vault vault-minimal

echo ""
echo "Waiting for LoadBalancer to provision (this may take 2-3 minutes)..."

# Wait for LoadBalancer to get an external IP/hostname
EXTERNAL_IP=""
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc -n vault vault-minimal -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get svc -n vault vault-minimal -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    fi
    
    if [ ! -z "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "<pending>" ]; then
        break
    fi
    
    echo "  Attempt $i/30: Still provisioning..."
    sleep 10
done

if [ ! -z "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "<pending>" ]; then
    echo ""
    echo "🎉 SUCCESS! Vault is publicly accessible!"
    echo "🌐 Vault URL: http://$EXTERNAL_IP:8200"
    echo "🔑 Root Token: myroot"
    echo ""
    echo "You can now:"
    echo "1. Open http://$EXTERNAL_IP:8200 in your browser"
    echo "2. Login with token: myroot"
    echo "3. Use Vault CLI with:"
    echo "   export VAULT_ADDR=http://$EXTERNAL_IP:8200"
    echo "   export VAULT_TOKEN=myroot"
    echo "   vault status"
    echo ""
    
    # Test if Vault is actually responding
    echo "Testing Vault connectivity..."
    if curl -s -m 10 "http://$EXTERNAL_IP:8200/v1/sys/health" > /dev/null; then
        echo "✅ Vault is responding to HTTP requests!"
    else
        echo "⚠️  LoadBalancer is ready but Vault may still be starting up"
        echo "   Wait a minute and try accessing the URL above"
    fi
    
else
    echo "⏳ LoadBalancer is still being provisioned..."
    echo "Run this script again in a few minutes, or check:"
    echo "kubectl get svc -n vault vault-minimal"
fi
