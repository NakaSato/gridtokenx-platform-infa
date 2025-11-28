#!/bin/bash

# GridTokenX Kubernetes Deployment Script
# Usage: ./deploy.sh [dev|prod]

set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="gridtokenx"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Deploying GridTokenX to Kubernetes (Environment: $ENVIRONMENT)"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if kustomize is installed
if ! command -v kustomize &> /dev/null; then
    print_warning "kustomize is not installed. Using kubectl kustomize instead."
    KUSTOMIZE_CMD="kubectl kustomize"
else
    KUSTOMIZE_CMD="kustomize"
fi

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    print_error "Invalid environment. Use 'dev' or 'prod'"
    exit 1
fi

echo ""
echo "📋 Pre-deployment checks..."

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi
print_status "Kubernetes cluster is accessible"

# Create namespace if it doesn't exist
if kubectl get namespace $NAMESPACE &> /dev/null; then
    print_status "Namespace '$NAMESPACE' already exists"
else
    echo "Creating namespace '$NAMESPACE'..."
    kubectl create namespace $NAMESPACE
    print_status "Namespace '$NAMESPACE' created"
fi

echo ""
echo "🔐 Setting up secrets..."

# Check if secrets exist
if kubectl get secret gridtokenx-secrets -n $NAMESPACE &> /dev/null; then
    print_warning "Secrets already exist. Skipping secret creation."
    read -p "Do you want to update secrets? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete secret gridtokenx-secrets -n $NAMESPACE
        kubectl delete secret postgres-credentials -n $NAMESPACE
        print_status "Existing secrets deleted"
    fi
fi

# Generate random secrets for production
if [[ "$ENVIRONMENT" == "prod" ]]; then
    print_warning "Production environment detected. Please ensure you have set proper secrets!"
    read -p "Have you updated the secrets in k8s/base/secrets.yaml? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Please update secrets before deploying to production."
        exit 1
    fi
fi

echo ""
echo "🏗️  Building Kubernetes manifests..."

# Build manifests using kustomize
OVERLAY_DIR="$K8S_DIR/overlays/$ENVIRONMENT"

if [[ ! -d "$OVERLAY_DIR" ]]; then
    print_error "Overlay directory not found: $OVERLAY_DIR"
    exit 1
fi

print_status "Using overlay: $OVERLAY_DIR"

# Validate manifests
echo "Validating manifests..."
if $KUSTOMIZE_CMD build "$OVERLAY_DIR" > /tmp/gridtokenx-manifests.yaml; then
    print_status "Manifests validated successfully"
else
    print_error "Manifest validation failed"
    exit 1
fi

# Show what will be deployed
echo ""
echo "📦 Resources to be deployed:"
kubectl kustomize "$OVERLAY_DIR" | grep "^kind:" | sort | uniq -c

echo ""
read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled"
    exit 0
fi

echo ""
echo "🚀 Deploying to Kubernetes..."

# Apply manifests
kubectl apply -k "$OVERLAY_DIR"

print_status "Manifests applied successfully"

echo ""
echo "⏳ Waiting for deployments to be ready..."

# Wait for deployments
DEPLOYMENTS=(
    "apigateway"
    "explorer"
    "trading"
    "website"
    "smartmeter"
    "mailpit"
    "anchor"
    "solana-validator"
)

for deployment in "${DEPLOYMENTS[@]}"; do
    echo "Waiting for $deployment..."
    if kubectl rollout status deployment/${ENVIRONMENT}-${deployment} -n $NAMESPACE --timeout=300s; then
        print_status "$deployment is ready"
    else
        print_warning "$deployment is not ready yet"
    fi
done

# Wait for StatefulSets
echo "Waiting for postgres..."
if kubectl rollout status statefulset/${ENVIRONMENT}-postgres -n $NAMESPACE --timeout=300s; then
    print_status "postgres is ready"
else
    print_warning "postgres is not ready yet"
fi

echo "Waiting for redis..."
if kubectl rollout status statefulset/${ENVIRONMENT}-redis -n $NAMESPACE --timeout=300s; then
    print_status "redis is ready"
else
    print_warning "redis is not ready yet"
fi

echo ""
echo "✅ Deployment complete!"

echo ""
echo "📊 Deployment Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get pods -n $NAMESPACE
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "🌐 Services:"
kubectl get svc -n $NAMESPACE

echo ""
echo "🔗 Ingress:"
kubectl get ingress -n $NAMESPACE

echo ""
echo "📝 Next steps:"
echo "  1. Check pod logs: kubectl logs -n $NAMESPACE <pod-name>"
echo "  2. Port-forward services: kubectl port-forward -n $NAMESPACE svc/<service-name> <local-port>:<service-port>"
echo "  3. Access Ingress: Add 'gridtokenx.local' to /etc/hosts pointing to your Ingress IP"
echo "  4. Monitor HPA: kubectl get hpa -n $NAMESPACE"
echo ""
echo "🎉 GridTokenX is now running on Kubernetes!"
