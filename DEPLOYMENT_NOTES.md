# Vault Deployment Notes

## Issue Resolution: Helm Release Name Conflict

### Problem
The Helm release name "vault" was already in use from a previous failed deployment, causing the error:
"cannot re-use a name that is still in use"

### Solution Applied
Changed the Helm release name from "vault" to "vault-v2" to avoid conflicts with any existing release.

### Changes Made

1. **Helm Release Name**: Changed from "vault" to "vault-v2"
2. **Service Account Names**: 
   - Server: "vault" → "vault-v2"
   - Agent Injector: "vault-agent-injector" → "vault-v2-agent-injector"
3. **Output Values**: Updated service names in outputs.tf to reflect new names
4. **Removed Complex Replacement Logic**: Simplified configuration by removing random ID and lifecycle blocks

### Service Names After Deployment
- Main Vault service: `vault-v2`
- Vault UI service: `vault-v2-ui`
- Agent Injector service: `vault-v2-agent-injector`

### Post-Deployment Scripts
The scripts in the `scripts/` directory default to using service name "vault", but can be overridden:
```bash
export VAULT_SERVICE_NAME="vault-v2"
./scripts/init-vault.sh
```

### Future Cleanup
Once this deployment is successful, the old "vault" release (if any) can be manually cleaned up:
```bash
helm uninstall vault -n vault
```

## Current Configuration
- **Simplified deployment**: Single-node, no HA, no TLS
- **AWS KMS auto-unseal**: Enabled
- **Storage**: File storage with persistent volume
- **Authentication**: AWS exec-based authentication for Terraform providers
