#!/bin/bash

# Quick access script for Vault minimal deployment
NAMESPACE="vault"
SERVICE_NAME="vault-minimal"
LOCAL_PORT="8200"
VAULT_PORT="8200"

echo "🚀 Starting Vault access..."
echo "Namespace: $NAMESPACE"
echo "Service: $SERVICE_NAME"
echo "Local URL: http://localhost:$LOCAL_PORT"
echo "Root Token: myroot"
echo ""

# Check if service exists
echo "Checking service status..."
kubectl get svc -n $NAMESPACE $SERVICE_NAME

echo ""
echo "Starting port-forward..."
echo "Open http://localhost:$LOCAL_PORT in your browser"
echo "Use token 'myroot' to login"
echo "Press Ctrl+C to stop"
echo ""

kubectl port-forward -n $NAMESPACE svc/$SERVICE_NAME $LOCAL_PORT:$VAULT_PORT
