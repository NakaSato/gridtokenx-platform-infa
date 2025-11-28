#!/bin/bash

# GridTokenX Kubernetes Cleanup Script
# Usage: ./cleanup.sh [dev|prod]

set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="gridtokenx"

echo "🗑️  Cleaning up GridTokenX Kubernetes resources (Environment: $ENVIRONMENT)"

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    print_error "Invalid environment. Use 'dev' or 'prod'"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    print_warning "Namespace '$NAMESPACE' does not exist. Nothing to clean up."
    exit 0
fi

echo ""
print_warning "This will delete ALL GridTokenX resources in the '$NAMESPACE' namespace!"
print_warning "Environment: $ENVIRONMENT"
echo ""

# Show what will be deleted
echo "📦 Resources to be deleted:"
kubectl get all -n $NAMESPACE 2>/dev/null || true
echo ""
kubectl get pvc -n $NAMESPACE 2>/dev/null || true
echo ""

read -p "Are you sure you want to continue? (yes/NO): " -r
echo
if [[ ! $REPLY == "yes" ]]; then
    print_warning "Cleanup cancelled"
    exit 0
fi

echo ""
echo "🗑️  Deleting resources..."

# Delete using kustomize
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(dirname "$SCRIPT_DIR")"
OVERLAY_DIR="$K8S_DIR/overlays/$ENVIRONMENT"

if [[ -d "$OVERLAY_DIR" ]]; then
    kubectl delete -k "$OVERLAY_DIR" --ignore-not-found=true
    print_status "Resources deleted via kustomize"
else
    print_warning "Overlay directory not found, deleting namespace instead"
fi

# Ask about PVCs
echo ""
read -p "Do you want to delete Persistent Volume Claims (this will DELETE ALL DATA)? (yes/NO): " -r
echo
if [[ $REPLY == "yes" ]]; then
    kubectl delete pvc --all -n $NAMESPACE
    print_status "PVCs deleted"
else
    print_warning "PVCs preserved"
fi

# Ask about namespace
echo ""
read -p "Do you want to delete the namespace '$NAMESPACE'? (yes/NO): " -r
echo
if [[ $REPLY == "yes" ]]; then
    kubectl delete namespace $NAMESPACE
    print_status "Namespace deleted"
else
    print_warning "Namespace preserved"
fi

echo ""
echo "✅ Cleanup complete!"
