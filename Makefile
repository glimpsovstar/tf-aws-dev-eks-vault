# Vault on EKS Terraform Makefile
# This Makefile provides convenient commands for managing the Vault deployment

.PHONY: help init plan apply destroy validate fmt check-fmt check-lint clean

# Default target
help: ## Show this help message
	@echo "Vault on EKS Terraform Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform (run this first)
	@echo "🚀 Initializing Terraform..."
	terraform init

validate: ## Validate Terraform configuration
	@echo "✅ Validating Terraform configuration..."
	terraform validate

fmt: ## Format Terraform files
	@echo "🎨 Formatting Terraform files..."
	terraform fmt -recursive

check-fmt: ## Check if Terraform files are formatted
	@echo "🔍 Checking Terraform formatting..."
	terraform fmt -check -recursive

plan: validate ## Create Terraform execution plan
	@echo "📋 Creating Terraform plan..."
	terraform plan -out=tfplan

apply: ## Apply Terraform configuration (requires plan)
	@echo "🚀 Applying Terraform configuration..."
	@if [ ! -f tfplan ]; then \
		echo "❌ No plan file found. Run 'make plan' first."; \
		exit 1; \
	fi
	terraform apply tfplan
	@rm -f tfplan

deploy: plan apply ## Plan and apply in one command

destroy: ## Destroy all Terraform-managed infrastructure
	@echo "⚠️  WARNING: This will destroy all Vault infrastructure!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read
	terraform destroy

clean: ## Clean up temporary files
	@echo "🧹 Cleaning up temporary files..."
	@rm -f tfplan
	@rm -f terraform.tfstate.backup

# Vault-specific commands
vault-status: ## Check Vault status (requires kubectl access)
	@echo "📊 Checking Vault status..."
	kubectl get pods -n vault
	kubectl get svc -n vault
	kubectl get secrets -n vault

vault-logs: ## Show Vault logs
	@echo "📋 Showing Vault logs..."
	kubectl logs -n vault -l app.kubernetes.io/name=vault -f

vault-port-forward: ## Port forward to Vault UI (localhost:8200)
	@echo "🔗 Port forwarding to Vault UI..."
	@echo "Access Vault at: https://localhost:8200"
	kubectl port-forward -n vault svc/vault 8200:8200

# Development commands
check-prerequisites: ## Check if all prerequisites are met
	@echo "🔍 Checking prerequisites..."
	@command -v terraform >/dev/null 2>&1 || { echo "❌ terraform is required but not installed."; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed."; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "❌ aws cli is required but not installed."; exit 1; }
	@echo "✅ All prerequisites are installed."

check-eks-access: ## Verify EKS cluster access
	@echo "🔍 Checking EKS cluster access..."
	@kubectl cluster-info --request-timeout=10s || { echo "❌ Cannot access EKS cluster. Check your kubectl config."; exit 1; }
	@echo "✅ EKS cluster is accessible."

# CI/CD friendly commands (for Terraform Cloud)
ci-validate: ## Validate for CI/CD
	terraform init -backend=false
	terraform validate
	terraform fmt -check=true

ci-plan: ## Plan for CI/CD
	terraform plan -input=false -no-color

ci-apply: ## Apply for CI/CD
	terraform apply -input=false -auto-approve -no-color