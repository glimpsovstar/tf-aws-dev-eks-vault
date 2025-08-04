#!/bin/bash

# Vault Initialization Script
# This script initializes and unseals Vault after deployment

set -e

# Configuration
VAULT_NAMESPACE=${VAULT_NAMESPACE:-vault}
VAULT_SERVICE_NAME=${VAULT_SERVICE_NAME:-vault}
VAULT_PORT=${VAULT_PORT:-8200}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        echo_error "kubectl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo_error "jq is required but not installed"
        exit 1
    fi
    
    echo_success "Prerequisites check passed"
}

# Wait for Vault pods to be ready
wait_for_vault() {
    echo_info "Waiting for Vault pods to be ready..."
    
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/name=vault \
        -n $VAULT_NAMESPACE \
        --timeout=300s
    
    echo_success "Vault pods are ready"
}

# Check if Vault is already initialized
check_vault_status() {
    echo_info "Checking Vault initialization status..."
    
    # Port forward to Vault
    kubectl port-forward -n $VAULT_NAMESPACE svc/$VAULT_SERVICE_NAME $VAULT_PORT:$VAULT_PORT &
    PF_PID=$!
    sleep 5
    
    # Check initialization status
    if curl -k -s https://localhost:$VAULT_PORT/v1/sys/init | jq -r '.initialized' | grep -q true; then
        echo_success "Vault is already initialized"
        kill $PF_PID 2>/dev/null || true
        return 0
    else
        echo_info "Vault is not initialized yet"
        kill $PF_PID 2>/dev/null || true
        return 1
    fi
}

# Initialize Vault
initialize_vault() {
    echo_info "Initializing Vault..."
    
    # Port forward to Vault
    kubectl port-forward -n $VAULT_NAMESPACE svc/$VAULT_SERVICE_NAME $VAULT_PORT:$VAULT_PORT &
    PF_PID=$!
    sleep 5
    
    # Initialize Vault
    INIT_RESPONSE=$(curl -k -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"secret_shares": 5, "secret_threshold": 3}' \
        https://localhost:$VAULT_PORT/v1/sys/init)
    
    # Save keys to Kubernetes secret
    echo "$INIT_RESPONSE" | kubectl create secret generic vault-init-keys \
        -n $VAULT_NAMESPACE \
        --from-file=keys.json=/dev/stdin
    
    # Extract root token for immediate use
    ROOT_TOKEN=$(echo "$INIT_RESPONSE" | jq -r '.root_token')
    
    kill $PF_PID 2>/dev/null || true
    
    echo_success "Vault initialized successfully"
    echo_warning "Unseal keys and root token saved to 'vault-init-keys' secret in $VAULT_NAMESPACE namespace"
    echo_warning "Root token: $ROOT_TOKEN"
    echo_warning "Please save this token securely and remove it from this output!"
}

# Enable Kubernetes auth method
enable_k8s_auth() {
    echo_info "Enabling Kubernetes authentication..."
    
    # Get the root token from the secret
    ROOT_TOKEN=$(kubectl get secret vault-init-keys -n $VAULT_NAMESPACE -o jsonpath='{.data.keys\.json}' | base64 -d | jq -r '.root_token')
    
    # Port forward to Vault
    kubectl port-forward -n $VAULT_NAMESPACE svc/$VAULT_SERVICE_NAME $VAULT_PORT:$VAULT_PORT &
    PF_PID=$!
    sleep 5
    
    # Enable Kubernetes auth
    curl -k -s -X POST \
        -H "X-Vault-Token: $ROOT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"type": "kubernetes"}' \
        https://localhost:$VAULT_PORT/v1/sys/auth/kubernetes
    
    # Configure Kubernetes auth
    KUBERNETES_HOST="https://kubernetes.default.svc.cluster.local"
    SA_TOKEN=$(kubectl get secret -n $VAULT_NAMESPACE \
        $(kubectl get sa vault -n $VAULT_NAMESPACE -o jsonpath='{.secrets[0].name}') \
        -o jsonpath='{.data.token}' | base64 -d)
    SA_CA_CRT=$(kubectl get secret -n $VAULT_NAMESPACE \
        $(kubectl get sa vault -n $VAULT_NAMESPACE -o jsonpath='{.secrets[0].name}') \
        -o jsonpath='{.data.ca\.crt}' | base64 -d)
    
    curl -k -s -X POST \
        -H "X-Vault-Token: $ROOT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"kubernetes_host\": \"$KUBERNETES_HOST\",
            \"kubernetes_ca_cert\": \"$SA_CA_CRT\",
            \"token_reviewer_jwt\": \"$SA_TOKEN\"
        }" \
        https://localhost:$VAULT_PORT/v1/auth/kubernetes/config
    
    kill $PF_PID 2>/dev/null || true
    
    echo_success "Kubernetes authentication enabled"
}

# Main execution
main() {
    echo_info "Starting Vault initialization process..."
    
    check_prerequisites
    wait_for_vault
    
    if check_vault_status; then
        echo_info "Vault is already initialized. Skipping initialization."
    else
        initialize_vault
        enable_k8s_auth
    fi
    
    echo_success "Vault initialization completed!"
    echo_info "You can now access Vault at https://localhost:8200 using port forwarding:"
    echo_info "kubectl port-forward -n $VAULT_NAMESPACE svc/$VAULT_SERVICE_NAME 8200:8200"
}

# Run main function
main "$@"