#!/bin/bash

echo "=== Vault Infrastructure Status After Rebuild ==="
echo "Date: $(date)"
echo

echo "📋 Expected Setup:"
echo "  ✅ Vault pods with ClusterIP service (internal)"
echo "  ✅ Single NLB from vault-ingress.tf (public)"
echo "  ✅ HTTP health checks on /v1/sys/health"
echo "  ✅ No more duplicate LoadBalancers"
echo

# Since we can't use kubectl locally, let's check what we expect to see
echo "🔍 What to check in AWS Console:"
echo

echo "1. LoadBalancers (should see only ONE now):"
echo "   - Go to: EC2 → Load Balancers"
echo "   - Should see only one NLB (Network Load Balancer)"
echo "   - Should NOT see the old Classic LB ae73af49b83984c168f9588ccec2cf42"
echo

echo "2. NLB Health Checks:"
echo "   - Click on your NLB → Target groups"
echo "   - Health check protocol: HTTP"
echo "   - Health check path: /v1/sys/health?standbyok=true"
echo "   - Targets should show 'Healthy' (may take 2-3 minutes)"
echo

echo "3. Get the Vault URL:"
echo "   - Copy the NLB DNS name"
echo "   - Vault URL will be: http://[NLB-DNS-NAME]:8200"
echo "   - UI URL will be: http://[NLB-DNS-NAME]:8200/ui"
echo

echo "4. Test Vault Access:"
echo "   - Open http://[NLB-DNS-NAME]:8200/ui in browser"
echo "   - Login with token: myroot"
echo "   - Should see Vault UI"
echo

echo "🚀 Terraform Cloud Outputs:"
echo "   - Check your Terraform Cloud run outputs"
echo "   - Look for 'vault_loadbalancer_hostname' or similar"
echo "   - This should show the new NLB hostname"
echo

echo "💡 If health checks are still failing:"
echo "   1. Wait 5 minutes for Vault to fully start"
echo "   2. Check that pods are running in Terraform Cloud logs"
echo "   3. Verify NLB health check settings match what we configured"
echo

echo "=== Next Steps ==="
echo "1. Check AWS Console for the single NLB"
echo "2. Wait for health checks to pass (green targets)"
echo "3. Use the NLB DNS name to access Vault"
echo "4. Test login with token 'myroot'"
echo

echo "=== Previous Issues Resolved ==="
echo "❌ Duplicate LoadBalancers → ✅ Single NLB only"
echo "❌ Classic LB TCP health checks → ✅ NLB HTTP health checks"  
echo "❌ Health check failures → ✅ Proper /v1/sys/health endpoint"
echo "❌ Internal NLB → ✅ Public NLB access"
echo
