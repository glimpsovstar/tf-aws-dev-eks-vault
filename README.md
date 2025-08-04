# Terraform Vault Deployment on AWS EKS

This repository deploys HashiCorp Vault on an existing Amazon EKS cluster in ap-southeast-2.

## 🚀 Features

- ✅ Deploys Vault in High Availability mode (3 replicas)
- ✅ Uses AWS KMS Auto-Unseal for security
- ✅ Configures TLS certificates for secure communication
- ✅ Integrates with Terraform Cloud remote state
- ✅ Includes comprehensive initialization and management scripts
- ✅ Supports Kubernetes authentication
- ✅ Ready for Terraform Cloud deployment

## 📌 Prerequisites

Ensure the following are completed before deploying:

- [ ] **EKS cluster is deployed** from `tf-aws-dev-eks` repository
- [ ] **KMS key for auto-unseal** is created (handled by EKS deployment)
- [ ] **Vault IAM service account role** is configured (handled by EKS deployment)
- [ ] **Terraform Cloud workspace** is configured for this repository
- [ ] **Terraform >= 1.0** is available
- [ ] **kubectl access** to your EKS cluster (for post-deployment tasks)

## 🔧 Configuration

### Terraform Cloud Variables

Set these variables in your Terraform Cloud workspace:

| Variable | Type | Description | Required | Default |
|----------|------|-------------|----------|---------|
| `aws_region` | string | AWS region | ✅ | `ap-southeast-2` |
| `environment` | string | Environment name | ✅ | `dev` |
| `vault_namespace` | string | Kubernetes namespace | ❌ | `vault` |
| `vault_replicas` | number | Number of Vault replicas | ❌ | `3` |
| `enable_vault_ui` | bool | Enable Vault web UI | ❌ | `true` |
| `enable_ingress` | bool | Enable external ingress | ❌ | `false` |
| `eks_workspace_name` | string | EKS workspace name | ❌ | `tf-aws-dev-eks` |
| `terraform_organization` | string | Terraform org name | ❌ | `djoo-hashicorp` |
| `tls_email` | string | Email for TLS certificates | ❌ | `""` |
| `vault_dns_name` | string | DNS name for Vault | ❌ | `""` |

### terraform.auto.tfvars

For local development or additional configuration:

```hcl
# Required if different from defaults
tls_email      = "your-email@example.com"
vault_dns_name = "vault.your-domain.com"

# Optional overrides
vault_replicas = 3
enable_vault_ui = true
enable_ingress = false
```

## � Deployment

### Option 1: Terraform Cloud (Recommended)

1. **Configure workspace variables** in Terraform Cloud
2. **Queue a plan** in Terraform Cloud
3. **Apply the configuration** from Terraform Cloud UI

### Option 2: Local Development

```bash
# Clone and setup
git clone <this-repo>
cd tf-aws-dev-eks-vault

# Initialize Terraform
make init

# Plan deployment
make plan

# Apply (requires plan first)
make apply

# Or combine plan + apply
make deploy
```

## 📋 Post-Deployment Tasks

After successful deployment, run these commands to initialize Vault:

```bash
# Initialize Vault and setup auto-unseal
./scripts/init-vault.sh

# Setup Kubernetes authentication (requires root token)
./scripts/setup-k8s-auth.sh -t YOUR_ROOT_TOKEN

# Access Vault UI locally
./scripts/port-forward.sh
# Then visit: https://localhost:8200
```

## 🛠️ Management Commands

Use the provided Makefile for common operations:

```bash
# Check Vault status
make vault-status

# View Vault logs
make vault-logs

# Port forward to Vault UI
make vault-port-forward

# Check prerequisites
make check-prerequisites

# Validate configuration
make validate

# Format Terraform files
make fmt

# Clean up temporary files
make clean
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│                EKS Cluster                  │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐    │
│  │         Vault Namespace             │    │
│  │  ┌─────────┐  ┌─────────┐  ┌──────┐ │    │
│  │  │ Vault-0 │  │ Vault-1 │  │Vault-2│ │    │
│  │  └─────────┘  └─────────┘  └──────┘ │    │
│  │                                     │    │
│  │  ┌─────────────────────────────────┐ │    │
│  │  │      Agent Injector           │ │    │
│  │  └─────────────────────────────────┘ │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
              │
              ▼
    ┌─────────────────────┐
    │     AWS KMS         │
    │   (Auto-Unseal)     │
    └─────────────────────┘
```

## 🔒 Security Features

- **KMS Auto-Unseal**: Vault automatically unseals using AWS KMS
- **TLS Encryption**: All communication is encrypted with TLS
- **RBAC**: Kubernetes Role-Based Access Control
- **IAM Integration**: Uses IRSA for AWS permissions
- **Network Security**: Runs in private subnets

## 🧹 Cleanup

To remove all Vault infrastructure:

```bash
# Using Makefile
make destroy

# Or directly with Terraform
terraform destroy
```

## 📚 Additional Resources

- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Vault on Kubernetes Guide](https://learn.hashicorp.com/tutorials/vault/kubernetes-raft-deployment-guide)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)

## 🐛 Troubleshooting

### Common Issues

1. **Pods not starting**: Check EBS CSI driver is installed
2. **KMS permissions**: Verify IAM role has KMS access
3. **TLS issues**: Check certificate generation
4. **Remote state**: Verify EKS workspace outputs are available

### Getting Help

```bash
# Check pod status
kubectl get pods -n vault

# Check pod logs
kubectl logs -n vault vault-0

# Describe pod for events
kubectl describe pod -n vault vault-0

# Check Vault status
kubectl exec -n vault vault-0 -- vault status
```
