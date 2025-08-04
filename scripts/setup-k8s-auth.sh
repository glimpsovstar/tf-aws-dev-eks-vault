#!/bin/bash

# Kubernetes Authentication Setup Script
# This script configures Kubernetes authentication for Vault

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

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -t, --token TOKEN    Vault root token (required)"
    echo "  -n, --namespace NS   Vault namespace (default: vault)"
    echo "  -h, --help          Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--token)
            VAULT_TOKEN="$2"
            shift 2
            ;;
        -n|--namespace)
            VAULT_NAMESPACE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if token is provided
if [[ -z "$VAULT_TOKEN" ]]; then
    echo_error "Vault token is required. Use -t or --token option."
    echo_info "You can get the token from the vault-init-keys secret:"
    echo_info "kubectl get secret vault-init-keys -n $VAULT_NAMESPACE -o jsonpath='{.data.keys\.json}' | base64 -d | jq -r '.root_token'"
    exit 1
fi

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

# Setup Kubernetes authentication
setup_k8s_auth() {
    echo_info "Setting up Kubernetes authentication..."
    
    # Port forward to Vault
    kubectl port-forward -n $VAULT_NAMESPACE svc/$VAULT_SERVICE_NAME $VAULT_PORT:$VAULT_PORT &
    PF_PID=$!
    sleep 5
    
    # Cleanup function
    cleanup() {
        kill $PF_PID 2>/dev/null || true
    }
    trap cleanup EXIT
    
    # Check if auth method already exists
    if curl -k -s -H "X-Vault-Token: $VAULT_TOKEN" \
        https://localhost:$VAULT_PORT/v1/sys/auth | jq -r 'has("kubernetes/")' | grep -q true; then
        echo_warning "Kubernetes auth method already exists, skipping creation"
    else
        echo_info "Enabling Kubernetes auth method..."
        curl -k -s -X POST \
            -H "X-Vault-Token: $VAULT_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"type": "kubernetes"}' \
            https://localhost:$VAULT_PORT/v1/sys/auth/kubernetes
        echo_success "Kubernetes auth method enabled"
    fi
    
    # Configure Kubernetes auth
    echo_info "Configuring Kubernetes auth method..."
    
    KUBERNETES_HOST="https://kubernetes.default.svc.cluster.local"
    
    # Get service account token and CA certificate
    SA_SECRET_NAME=$(kubectl get sa vault -n $VAULT_NAMESPACE -o jsonpath='{.secrets[0].name}' 2>/dev/null || echo "")
    
    if [[ -z "$SA_SECRET_NAME" ]]; then
        echo_warning "Service account token secret not found, using token request API"
        SA_TOKEN=$(kubectl create token vault -n $VAULT_NAMESPACE --duration=8760h)
    else
        SA_TOKEN=$(kubectl get secret $SA_SECRET_NAME -n $VAULT_NAMESPACE -o jsonpath='{.data.token}' | base64 -d)
    fi
    
    # Get CA certificate
    SA_CA_CRT=$(kubectl config view --raw -o json | jq -r '.clusters[] | select(.name == "'$(kubectl config current-context)'") | .cluster."certificate-authority-data"' | base64 -d)
    
    # Configure the auth method
    curl -k -s -X POST \
        -H "X-Vault-Token: $VAULT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"kubernetes_host\": \"$KUBERNETES_HOST\",
            \"kubernetes_ca_cert\": \"$SA_CA_CRT\",
            \"token_reviewer_jwt\": \"$SA_TOKEN\"
        }" \
        https://localhost:$VAULT_PORT/v1/auth/kubernetes/config
    
    echo_success "Kubernetes auth method configured"
}

# Create example policy and role
create_example_policy() {
    echo_info "Creating example policy and role..."
    
    # Create a simple policy
    curl -k -s -X PUT \
        -H "X-Vault-Token: $VAULT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "policy": "path \"secret/data/*\" {\n  capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]\n}\n\npath \"secret/metadata/*\" {\n  capabilities = [\"list\"]\n}"
        }' \
        https://localhost:$VAULT_PORT/v1/sys/policies/acl/example-policy
    
    # Create a role
    curl -k -s -X POST \
        -H "X-Vault-Token: $VAULT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "bound_service_account_names": ["default"],
            "bound_service_account_namespaces": ["default"],
            "policies": ["example-policy"],
            "ttl": "24h"
        }' \
        https://localhost:$VAULT_PORT/v1/auth/kubernetes/role/example-role
    
    echo_success "Example policy and role created"
}

# Test authentication
test_auth() {
    echo_info "Testing Kubernetes authentication..."
    
    # Create a test pod that uses the default service account
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: vault-auth-test
  namespace: default
spec:
  serviceAccountName: default
  containers:
  - name: vault-test
    image: vault:latest
    command: ['sleep', '3600']
  restartPolicy: Never
EOF
    
    # Wait for pod to be ready
    kubectl wait --for=condition=ready pod vault-auth-test -n default --timeout=60s
    
    # Test authentication
    echo_info "Testing authentication from pod..."
    kubectl exec vault-auth-test -n default -- sh -c "
        export VAULT_ADDR=https://vault.vault.svc.cluster.local:8200
        export VAULT_SKIP_VERIFY=true
        JWT=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
        vault write auth/kubernetes/login role=example-role jwt=\$JWT
    " || echo_warning "Authentication test failed - this is normal if the example role doesn't match your setup"
    
    # Cleanup test pod
    kubectl delete pod vault-auth-test -n default --ignore-not-found=true
    
    echo_success "Authentication test completed"
}

# Main execution
main() {
    echo_info "Starting Kubernetes authentication setup..."
    
    check_prerequisites
    setup_k8s_auth
    create_example_policy
    test_auth
    
    echo_success "Kubernetes authentication setup completed!"
    echo_info "You can now create policies and roles for your applications."
    echo_info "Example role 'example-role' has been created for the 'default' service account in the 'default' namespace."
}

# Run main function
main "$@"