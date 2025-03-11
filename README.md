# Terraform Vault Deployment on AWS EKS

This repository deploys HashiCorp Vault on an existing Amazon EKS cluster in ap-southeast-2.

🚀 Features
Deploys Vault in Kubernetes
Uses AWS KMS Auto-Unseal
Configures Let'"'"'s Encrypt TLS certificates
Integrates with Terraform Cloud remote state
📌 Prerequisites
Ensure tf-aws-dev-eks is deployed first.
Fetch EKS details automatically from Terraform Cloud.
