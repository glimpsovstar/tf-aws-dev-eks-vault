#!/bin/bash

echo "=== Setting up kubectl access to EKS cluster ==="
echo "Date: $(date)"
echo

echo "🔍 Your EKS cluster was created by Terraform Cloud using 'tfstacks-role'"
echo "   You need to configure kubectl with the same AWS role"
echo

echo "📋 Method 1: Using AWS CLI with role assumption (Recommended)"
echo
echo "1. First, check your current AWS identity:"
echo "   aws sts get-caller-identity"
echo

echo "2. Configure AWS CLI to assume the tfstacks-role:"
echo "   # Add this to your ~/.aws/config file:"
echo "   [profile tfstacks]"
echo "   role_arn = arn:aws:iam::[YOUR-ACCOUNT-ID]:role/tfstacks-role"
echo "   source_profile = default"
echo "   region = ap-southeast-2"
echo

echo "3. Use the profile to configure kubectl:"
echo "   aws eks update-kubeconfig --region ap-southeast-2 --name vault-demo-cluster --profile tfstacks"
echo

echo "📋 Method 2: Direct role assumption (Alternative)"
echo
echo "1. Assume the tfstacks-role directly:"
echo "   aws sts assume-role --role-arn arn:aws:iam::[YOUR-ACCOUNT-ID]:role/tfstacks-role --role-session-name kubectl-session"
echo

echo "2. Export the temporary credentials:"
echo "   export AWS_ACCESS_KEY_ID=[AccessKeyId from step 1]"
echo "   export AWS_SECRET_ACCESS_KEY=[SecretAccessKey from step 1]"
echo "   export AWS_SESSION_TOKEN=[SessionToken from step 1]"
echo

echo "3. Configure kubectl:"
echo "   aws eks update-kubeconfig --region ap-southeast-2 --name vault-demo-cluster"
echo

echo "📋 Method 3: If you have admin access (Easiest)"
echo
echo "1. If you have admin permissions on the AWS account:"
echo "   aws eks update-kubeconfig --region ap-southeast-2 --name vault-demo-cluster"
echo

echo "2. Test access:"
echo "   kubectl get nodes"
echo "   kubectl get pods -n vault"
echo

echo "🔧 Finding your AWS Account ID:"
echo "   aws sts get-caller-identity --query Account --output text"
echo

echo "🔧 Alternative: Check from your existing AWS setup"
echo "   If you already have AWS CLI configured with access:"
echo "   1. aws eks update-kubeconfig --region ap-southeast-2 --name vault-demo-cluster"
echo "   2. kubectl get nodes"
echo "   3. If this works, you're already good to go!"
echo

echo "❓ Troubleshooting:"
echo "   - Error 'You must be logged in to the server': AWS creds issue"
echo "   - Error 'cluster vault-demo-cluster not found': Wrong region or cluster name"
echo "   - Error 'AccessDenied': Need tfstacks-role permissions"
echo

echo "🎯 Once kubectl works, you can debug Vault:"
echo "   kubectl get pods -n vault"
echo "   kubectl get svc -n vault"
echo "   kubectl describe pods -n vault"
echo "   kubectl logs -n vault [pod-name]"
echo
