# MINIMAL VAULT DEPLOYMENT STRATEGY

## What We Changed

### 🚀 **Ultra-Simplified Configuration**
- **Development Mode**: `server.dev.enabled = true` (in-memory storage)
- **No Persistence**: No PVCs, no storage classes to worry about
- **No TLS**: Disabled to avoid certificate issues
- **No Agent Injector**: Disabled to reduce complexity
- **Minimal Resources**: 128Mi RAM, 50m CPU
- **No Waiting**: `wait = false` so Terraform doesn't wait for pod readiness
- **5-minute timeout**: Fail fast if there are issues

### 🎯 **Why This Should Work**
1. **Development mode** starts Vault immediately without initialization
2. **In-memory storage** eliminates PVC/storage class issues
3. **No TLS** removes certificate complexity
4. **Minimal resources** should fit on any node
5. **No waiting** means Terraform completes quickly

### 🧪 **Testing**
After deployment, run:
```bash
./scripts/test-minimal-vault.sh
```

This will:
- Check pod status
- Test port-forwarding
- Verify Vault API responds
- Test basic authentication with root token "myroot"

### 📊 **Expected Behavior**
- **Terraform**: Should complete in ~5 minutes
- **Vault Pod**: Should start quickly (30-60 seconds)
- **Root Token**: `myroot` (for testing only!)
- **Vault Address**: `http://vault-minimal:8200` (inside cluster)

### 🔄 **Next Steps After Success**
Once this works, we can incrementally add back:
1. ✅ Persistent storage
2. ✅ TLS encryption  
3. ✅ AWS KMS auto-unseal
4. ✅ HA configuration
5. ✅ Agent injector

## Files Changed
- `vault-helm.tf` → Minimal configuration
- `vault-helm.tf.disabled` → Original complex config (backed up)
- `outputs.tf` → Updated service names
- `main.tf` → Simplified pre-flight checks
- `scripts/test-minimal-vault.sh` → New test script

## Commands
```bash
# Deploy
terraform plan
terraform apply

# Test (after deployment)
./scripts/test-minimal-vault.sh

# Access Vault UI
kubectl port-forward -n vault svc/vault-minimal 8200:8200
# Then open http://localhost:8200 with token "myroot"
```
