# Vault on EKS Deployment Guide

This guide walks you through deploying HashiCorp Vault on your existing EKS cluster using Terraform.

## Prerequisites Checklist

- [ ] EKS cluster is deployed and running (from `tf-aws-dev-eks` repository)
- [ ] EBS CSI driver is installed on the cluster
- [ ] KMS key for auto-unseal is created
- [ ] Vault IAM service account role is configured
- [ ] `kubectl` is configured to access your EKS cluster
- [ ] Terraform >= 1.0 is installed
- [ ] Helm 3.x is installed
- [ ] AWS CLI is configured
- [ ] `jq` is installed (for JSON parsing in scripts)

## Step 1: Clone and Setup Repository

```bash
# Clone this repository
git clone <your-vault-eks-repo-url>
cd vault-eks-terraform

# Make scripts executable
chmod +x scripts/*.sh

# Copy example variables
cp terraform.tfvars.example terraform.tfvars
```

## Step 2: Configure Variables

Edit `terraform.tfvars` with your specific values:

```hcl
# AWS Configuration
aws_region  = "ap-southeast-2"  # Match your EKS cluster region
environment = "dev"

# Vault Configuration
vault_namespace = "vault"
vault_replicas  = 3
enable_vault_ui = true

# Storage
storage_class = "vault-storage"  # Ensure this matches your EKS setup
storage_size  = "10Gi"

# Resource limits (adjust based on your needs)
vault_resources = {
  requests = {
    memory = "256Mi"
    cpu    = "250m"
  }
  limits = {
    memory = "1Gi"
    cpu    = "1000m"
  }
}
```

## Step 3: Terraform Cloud Configuration

1. **Create Terraform Cloud Workspace**:
   - Organization: `djoo-hashicorp`
   - Workspace name: `tf-aws-dev-eks-vault`

2. **Configure Workspace**:
   - Set VCS connection to this repository
   - Configure AWS credentials as environment variables:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`

3. **Verify Remote State Access**:
   - Ensure the workspace has access to read from `tf-aws-dev-eks` workspace
   - Check remote state outputs are available

## Step 4: Deploy Infrastructure

### Option A: Using Terraform CLI
```bash
# Initialize Terraform
make init

# Review the plan
make plan

# Apply the configuration
make apply
```

### Option B: Using Terraform Cloud UI
1. Queue a plan in Terraform Cloud
2. Review the planned changes
3. Apply if everything looks correct

## Step 5: Verify Deployment

```bash
# Check pod status
kubectl get pods -n vault

# Expected output:
# NAME                                   READY   STATUS    RESTARTS   AGE
# vault-0                               1/1     Running   0          5m
# vault-1                               1/1     Running   0          5m
# vault-2                               1/1     Running   0          5m
# vault-agent-injector-xxx-xxx          1/1     Running   0          5m

# Check Vault status (should show "sealed: false" due to auto-unseal)
make status
```

## Step 6: Initialize Vault

```bash
# Initialize Vault cluster
make init-vault

# This will:
# - Initialize Vault with 5 key shares (threshold: 3)
# - Save keys to vault-keys.json
# - Auto-unseal using KMS should activate automatically
```

**Important**: Securely store the `vault-keys.json` file and remove it from the deployment environment.

## Step 7: Setup Authentication

```bash
# Configure Kubernetes authentication
make setup-auth

# This enables applications in your cluster to authenticate with Vault
```

## Step 8: Access Vault

### Local Access (Recommended for initial setup)
```bash
# Start port forwarding
make port-forward

# In another terminal, set environment variables
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="<root-token-from-vault-keys.json>"

# Test connection
vault status
```

### Internal Cluster Access
Applications within the cluster can access Vault at:
- API: `https://vault.vault.svc.cluster.local:8200`
- UI: `https://vault-ui.vault.svc.cluster.local:8200`

### External Access (Optional)
If you enabled ingress (`enable_ingress = true`):
- Configure DNS to point to your ALB
- Access via `https://your-vault-domain.com`

## Step 9: Initial Configuration

1. **Enable Secret Engines**:
```bash
# Key-Value secrets
vault secrets enable -path=secret kv-v2

# Database secrets (example)
vault secrets enable database
```

2. **Create Policies**:
```bash
# Example policy
vault policy write example-policy - <<EOF
path "secret/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF
```

3. **Create Kubernetes Roles**:
```bash
# Example role for applications
vault write auth/kubernetes/role/example-app \
    bound_service_account_names=example-app \
    bound_service_account_namespaces=default \
    policies=example-policy \
    ttl=1h
```

## Step 10: Monitoring and Maintenance

### Health Checks
```bash
# Check overall health
make health

# View logs
make logs

# Check metrics (if enabled)
make metrics
```

### Backup
```bash
# Create snapshot backup
make backup
```

### Updates
To update Vault:
1. Update `vault_image_tag` in `terraform.tfvars`
2. Run `terraform apply`
3. Vault will perform rolling updates automatically

## Troubleshooting

### Common Issues

**1. Pods stuck in Pending**
```bash
# Check storage class
kubectl get storageclass

# Check PVC status  
kubectl get pvc -n vault

# Check node resources
kubectl describe nodes
```

**2. Vault not unsealing**
```bash
# Check KMS permissions
kubectl logs vault-0 -n vault | grep -i "kms\|unseal"

# Verify service account annotations
kubectl describe sa vault -n vault
```

**3. TLS certificate issues**
```bash
# Check certificate secret
kubectl get secret vault-tls -n vault -o yaml

# Recreate certificates if needed
terraform taint kubernetes_secret.vault_tls
terraform apply
```

**4. Authentication failures**
```bash
# Check Kubernetes auth configuration
vault read auth/kubernetes/config

# Verify service account token
kubectl exec vault-0 -n vault -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

### Useful Commands

```bash
# Get shell access to Vault pod
make shell

# Port forward for local access
make port-forward

# Check Vault UI access info
make ui

# Clean up local files
make clean

# Full redeployment
make destroy && make deploy
```

## Security Best Practices

1. **Secure the Root Token**:
   - Use the root token only for initial setup
   - Create administrative policies and tokens
   - Revoke the root token when no longer needed

2. **Key Management**:
   - Store unseal keys securely (even though auto-unseal is configured)
   - Distribute keys to multiple trusted operators
   - Consider using Shamir's secret sharing for additional security

3. **Network Security**:
   - Use internal load balancer for production
   - Implement network policies to restrict access
   - Enable audit logging for compliance

4. **Regular Maintenance**:
   - Monitor Vault logs and metrics
   - Perform regular snapshots
   - Keep Vault updated to latest stable version
   - Review and rotate certificates regularly

## Next Steps

1. **Configure Secret Engines**: Set up secret engines for your specific use cases
2. **Implement Auth Methods**: Configure additional authentication methods (LDAP, OIDC, etc.)
3. **Policy Management**: Create fine-grained policies for different applications
4. **Monitoring Setup**: Integrate with Prometheus/Grafana for monitoring
5. **Backup Strategy**: Implement automated backup procedures
6. **Disaster Recovery**: Document and test recovery procedures

## Support

For issues and questions:
- Check the troubleshooting section above
- Review Vault logs: `make logs`
- Consult HashiCorp Vault documentation
- Open an issue in this repository

---

**Remember**: Always test deployments in a non-production environment first!