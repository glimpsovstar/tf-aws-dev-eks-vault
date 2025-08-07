#!/bin/bash

echo "=== Debugging Vault Backend Issues ==="
echo "Date: $(date)"
echo

echo "🔍 The LoadBalancer health checks are failing, which means:"
echo "   1. Vault pods might not be running"
echo "   2. Vault is not responding on port 8200"
echo "   3. Service selector is not matching pods"
echo "   4. Health check path is incorrect"
echo

echo "📋 Steps to debug in Terraform Cloud logs:"
echo

echo "1. Check if Vault pods are running:"
echo "   Look for these in your Terraform Cloud apply logs:"
echo "   - 'helm_release.vault: Creation complete'"
echo "   - No errors about pod creation failures"
echo

echo "2. Common Vault startup issues:"
echo "   - Insufficient memory (we set 128Mi - might be too low)"
echo "   - Dev mode failing to initialize"
echo "   - Port conflicts"
echo "   - Missing environment variables"
echo

echo "3. Check Helm release name and labels:"
echo "   - Helm release name: 'vault-minimal'"
echo "   - Expected pod labels: app.kubernetes.io/name=vault, app.kubernetes.io/instance=vault"
echo "   - But actual labels might be: app.kubernetes.io/instance=vault-minimal"
echo

echo "🚨 LIKELY ISSUE: Label mismatch!"
echo "   The service selector uses instance='vault'"
echo "   But Helm release name is 'vault-minimal'"
echo "   So actual pod labels might be instance='vault-minimal'"
echo

echo "💡 Quick fixes to try:"
echo

echo "   Option 1: Change Helm release name to 'vault'"
echo "   Option 2: Update service selector to match 'vault-minimal'"
echo "   Option 3: Increase memory allocation"
echo "   Option 4: Simplify health check path"
echo

echo "🔧 Let's try the most likely fix first..."
echo "   Updating service selector to match Helm release name 'vault-minimal'"
echo
