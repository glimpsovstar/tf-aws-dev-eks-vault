#!/bin/bash

# Vault CLI access script
export VAULT_NAMESPACE="vault"
export VAULT_SERVICE="vault-minimal"
export VAULT_TOKEN="myroot"

echo "🔐 Setting up Vault CLI access..."

# Start port-forward in background
kubectl port-forward -n $VAULT_NAMESPACE svc/$VAULT_SERVICE 8200:8200 &
PORT_FORWARD_PID=$!

# Wait for port-forward to establish
echo "Waiting for port-forward..."
sleep 3

# Set Vault environment variables
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

echo "✅ Vault environment configured:"
echo "   VAULT_ADDR: $VAULT_ADDR"
echo "   VAULT_TOKEN: $VAULT_TOKEN"
echo ""

# Test Vault connection
echo "🧪 Testing Vault connection..."
if command -v vault >/dev/null 2>&1; then
    vault status
    echo ""
    echo "🎯 Try these commands:"
    echo "   vault auth list"
    echo "   vault secrets list"
    echo "   vault kv put secret/hello foo=world"
    echo "   vault kv get secret/hello"
else
    echo "⚠️  Vault CLI not installed. Using curl instead..."
    echo "📊 Vault Status:"
    curl -s $VAULT_ADDR/v1/sys/health | jq '.' || curl -s $VAULT_ADDR/v1/sys/health
    echo ""
    echo "🔑 Auth Methods:"
    curl -s -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/sys/auth | jq '.' || echo "Use browser for full access"
fi

echo ""
echo "🌐 Web UI: http://localhost:8200"
echo "🔑 Token: myroot"
echo ""
echo "Press Enter to stop port-forward and exit..."
read

# Cleanup
kill $PORT_FORWARD_PID 2>/dev/null
echo "Port-forward stopped."
