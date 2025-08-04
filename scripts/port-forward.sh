#!/bin/bash

# Vault Port Forward Script
# This script creates a port forward to the Vault service for local access

set -e

# Configuration
VAULT_NAMESPACE=${VAULT_NAMESPACE:-vault}
VAULT_SERVICE_NAME=${VAULT_SERVICE_NAME:-vault}
LOCAL_PORT=${LOCAL_PORT:-8200}
VAULT_PORT=${VAULT_PORT:-8200}

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo_error "kubectl is required but not installed"
    exit 1
fi

# Check if Vault service exists
if ! kubectl get svc $VAULT_SERVICE_NAME -n $VAULT_NAMESPACE &> /dev/null; then
    echo_error "Vault service '$VAULT_SERVICE_NAME' not found in namespace '$VAULT_NAMESPACE'"
    exit 1
fi

echo_info "Starting port forward to Vault..."
echo_info "Namespace: $VAULT_NAMESPACE"
echo_info "Service: $VAULT_SERVICE_NAME"
echo_info "Local port: $LOCAL_PORT"
echo_info "Remote port: $VAULT_PORT"
echo ""
echo_success "Vault UI will be available at: https://localhost:$LOCAL_PORT"
echo_warning "Press Ctrl+C to stop port forwarding"
echo ""

# Start port forward
kubectl port-forward -n $VAULT_NAMESPACE svc/$VAULT_SERVICE_NAME $LOCAL_PORT:$VAULT_PORT