# GridTokenX Kubernetes Deployment

Complete Kubernetes deployment manifests for the GridTokenX platform, including all services, databases, and infrastructure components.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [Scaling](#scaling)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Overview

This Kubernetes deployment includes:

- **Database Layer**: PostgreSQL (StatefulSet), Redis (StatefulSet)
- **Blockchain Infrastructure**: Solana test validator, Anchor development service
- **Application Services**: API Gateway (Rust/Axum), Explorer (Next.js), Trading (Next.js), Website (Next.js), Smart Meter Simulator (Python/FastAPI)
- **Supporting Services**: Mailpit (email testing)
- **Networking**: Ingress with path-based routing, NetworkPolicy for security
- **Environments**: Dev and Production overlays with Kustomize

## Prerequisites

### Required Tools

- **kubectl** (v1.25+): Kubernetes command-line tool
- **kustomize** (v4.5+): Template-free customization of Kubernetes manifests (or use `kubectl kustomize`)
- **Kubernetes cluster** (v1.25+): Local (minikube, kind, k3s) or cloud (GKE, EKS, AKS)

### Cluster Requirements

- **Ingress Controller**: NGINX Ingress Controller (or modify ingress.yaml for your controller)
- **StorageClass**: `standard` StorageClass available (or modify PVC specs)
- **Metrics Server**: For HorizontalPodAutoscaler (optional but recommended)

### Install Ingress Controller (if not installed)

```bash
# For NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# For minikube
minikube addons enable ingress

# For kind
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml
```

### Install Metrics Server (for HPA)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Quick Start

### 1. Build Docker Images

First, build all Docker images and push to your registry:

```bash
# Build all images
cd /path/to/gridtokenx-platform

# API Gateway
docker build -t gridtokenx/apigateway:latest ./gridtokenx-apigateway

# Explorer
docker build -t gridtokenx/explorer:latest ./gridtokenx-explorer

# Trading
docker build -t gridtokenx/trading:latest ./gridtokenx-trading

# Website
docker build -t gridtokenx/website:latest ./gridtokenx-website

# Smart Meter Simulator
docker build -t gridtokenx/smartmeter:latest ./gridtokenx-smartmeter-simulator

# Anchor
docker build -t gridtokenx/anchor:latest ./gridtokenx-anchor

# Solana Test Validator
docker build -t gridtokenx/solana-test-validator:latest ./docker/solana-test-validator
```

### 2. Update Secrets

**IMPORTANT**: Before deploying to production, update the secrets in `k8s/base/secrets.yaml`:

```bash
# Edit secrets
vim k8s/base/secrets.yaml

# Update:
# - POSTGRES_PASSWORD
# - JWT_SECRET
# - API_KEY_SECRET
# - ENGINEERING_API_KEY
# - HMAC_SECRET
# - INFLUXDB_TOKEN
```

### 3. Deploy to Development

```bash
cd k8s
./scripts/deploy.sh dev
```

### 4. Deploy to Production

```bash
cd k8s
./scripts/deploy.sh prod
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Ingress                              │
│              (gridtokenx.local)                              │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Website    │    │   Explorer   │    │   Trading    │
│  (Next.js)   │    │  (Next.js)   │    │  (Next.js)   │
└──────────────┘    └──────────────┘    └──────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
                    ┌──────────────┐
                    │ API Gateway  │
                    │ (Rust/Axum)  │
                    │   + HPA      │
                    └──────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  PostgreSQL  │    │    Redis     │    │   Solana     │
│ (StatefulSet)│    │(StatefulSet) │    │  Validator   │
└──────────────┘    └──────────────┘    └──────────────┘
```

## Directory Structure

```
k8s/
├── base/                      # Base manifests
│   ├── namespace.yaml         # Namespace definition
│   ├── configmap.yaml         # Non-sensitive configuration
│   ├── secrets.yaml           # Sensitive configuration
│   └── kustomization.yaml     # Base kustomization
├── database/                  # Database layer
│   ├── postgres-statefulset.yaml
│   ├── postgres-service.yaml
│   ├── redis-statefulset.yaml
│   └── redis-service.yaml
├── blockchain/                # Blockchain infrastructure
│   ├── solana-validator-deployment.yaml
│   ├── solana-validator-service.yaml
│   ├── anchor-deployment.yaml
│   └── anchor-service.yaml
├── apps/                      # Application services
│   ├── apigateway-deployment.yaml
│   ├── apigateway-service.yaml
│   ├── apigateway-hpa.yaml
│   ├── explorer-deployment.yaml
│   ├── explorer-service.yaml
│   ├── trading-deployment.yaml
│   ├── trading-service.yaml
│   ├── website-deployment.yaml
│   ├── website-service.yaml
│   ├── smartmeter-deployment.yaml
│   ├── smartmeter-service.yaml
│   ├── mailpit-deployment.yaml
│   └── mailpit-service.yaml
├── networking/                # Networking configuration
│   ├── ingress.yaml           # Ingress rules
│   └── network-policy.yaml    # Network policies
├── overlays/                  # Environment-specific overlays
│   ├── dev/                   # Development environment
│   │   ├── kustomization.yaml
│   │   ├── configmap-patch.yaml
│   │   └── deployment-patches.yaml
│   └── prod/                  # Production environment
│       ├── kustomization.yaml
│       ├── configmap-patch.yaml
│       └── deployment-patches.yaml
└── scripts/                   # Helper scripts
    ├── deploy.sh              # Deployment script
    └── cleanup.sh             # Cleanup script
```

## Deployment

### Using Helper Scripts

#### Deploy

```bash
# Development
./scripts/deploy.sh dev

# Production
./scripts/deploy.sh prod
```

#### Cleanup

```bash
# Development
./scripts/cleanup.sh dev

# Production
./scripts/cleanup.sh prod
```

### Manual Deployment

#### Development

```bash
# Apply manifests
kubectl apply -k overlays/dev/

# Watch deployment progress
kubectl get pods -n gridtokenx -w
```

#### Production

```bash
# Apply manifests
kubectl apply -k overlays/prod/

# Watch deployment progress
kubectl get pods -n gridtokenx -w
```

### Verify Deployment

```bash
# Check all resources
kubectl get all -n gridtokenx

# Check pods
kubectl get pods -n gridtokenx

# Check services
kubectl get svc -n gridtokenx

# Check ingress
kubectl get ingress -n gridtokenx

# Check HPA
kubectl get hpa -n gridtokenx

# Check PVCs
kubectl get pvc -n gridtokenx
```

## Configuration

### Environment Variables

All configuration is managed through:
- **ConfigMap** (`k8s/base/configmap.yaml`): Non-sensitive configuration
- **Secrets** (`k8s/base/secrets.yaml`): Sensitive data

### Customizing Configuration

#### For Development

Edit `k8s/overlays/dev/configmap-patch.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gridtokenx-config
data:
  LOG_LEVEL: "debug"
  # Add your custom config
```

#### For Production

Edit `k8s/overlays/prod/configmap-patch.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gridtokenx-config
data:
  LOG_LEVEL: "info"
  SOLANA_RPC_URL: "https://api.mainnet-beta.solana.com"
  # Add your custom config
```

### Updating Secrets

```bash
# Delete existing secrets
kubectl delete secret gridtokenx-secrets -n gridtokenx

# Edit secrets file
vim k8s/base/secrets.yaml

# Reapply
kubectl apply -f k8s/base/secrets.yaml
```

## Scaling

### Manual Scaling

```bash
# Scale API Gateway
kubectl scale deployment apigateway -n gridtokenx --replicas=5

# Scale Explorer
kubectl scale deployment explorer -n gridtokenx --replicas=3
```

### Horizontal Pod Autoscaler (HPA)

The API Gateway has HPA enabled by default:

```bash
# Check HPA status
kubectl get hpa -n gridtokenx

# Describe HPA
kubectl describe hpa apigateway-hpa -n gridtokenx

# Edit HPA
kubectl edit hpa apigateway-hpa -n gridtokenx
```

### Resource Limits

Edit deployment patches in `k8s/overlays/{env}/deployment-patches.yaml`:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

## Monitoring

### Logs

```bash
# View API Gateway logs
kubectl logs -n gridtokenx -l app=apigateway --tail=100 -f

# View all logs
kubectl logs -n gridtokenx --all-containers=true --tail=100 -f

# View specific pod logs
kubectl logs -n gridtokenx <pod-name> -f
```

### Port Forwarding

```bash
# API Gateway
kubectl port-forward -n gridtokenx svc/apigateway 8080:8080

# Explorer
kubectl port-forward -n gridtokenx svc/explorer 3000:4000

# Trading
kubectl port-forward -n gridtokenx svc/trading 3001:3000

# PostgreSQL
kubectl port-forward -n gridtokenx svc/postgres 5432:5432

# Redis
kubectl port-forward -n gridtokenx svc/redis 6379:6379

# Mailpit Web UI
kubectl port-forward -n gridtokenx svc/mailpit 8025:8025
```

### Exec into Pods

```bash
# API Gateway
kubectl exec -it -n gridtokenx <apigateway-pod> -- /bin/sh

# PostgreSQL
kubectl exec -it -n gridtokenx postgres-0 -- psql -U gridtokenx_user -d gridtokenx

# Redis
kubectl exec -it -n gridtokenx redis-0 -- redis-cli
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n gridtokenx

# Describe pod
kubectl describe pod -n gridtokenx <pod-name>

# Check events
kubectl get events -n gridtokenx --sort-by='.lastTimestamp'
```

### Image Pull Errors

```bash
# Check if images exist
docker images | grep gridtokenx

# Push images to registry
docker push gridtokenx/apigateway:latest

# Update image pull policy
kubectl patch deployment apigateway -n gridtokenx -p '{"spec":{"template":{"spec":{"containers":[{"name":"apigateway","imagePullPolicy":"Always"}]}}}}'
```

### Database Connection Issues

```bash
# Check PostgreSQL logs
kubectl logs -n gridtokenx postgres-0

# Test connection
kubectl exec -it -n gridtokenx postgres-0 -- psql -U gridtokenx_user -d gridtokenx -c "SELECT 1"

# Check service
kubectl get svc postgres -n gridtokenx
```

### Ingress Not Working

```bash
# Check ingress
kubectl describe ingress gridtokenx-ingress -n gridtokenx

# Check ingress controller
kubectl get pods -n ingress-nginx

# Add to /etc/hosts
echo "127.0.0.1 gridtokenx.local" | sudo tee -a /etc/hosts

# Get ingress IP (for cloud)
kubectl get ingress -n gridtokenx
```

### HPA Not Scaling

```bash
# Check metrics server
kubectl get deployment metrics-server -n kube-system

# Check HPA status
kubectl describe hpa apigateway-hpa -n gridtokenx

# Check pod metrics
kubectl top pods -n gridtokenx
```

### Network Policy Issues

```bash
# Disable network policies temporarily
kubectl delete networkpolicy --all -n gridtokenx

# Check network policy
kubectl describe networkpolicy -n gridtokenx
```

## Common Commands

```bash
# Get all resources
kubectl get all -n gridtokenx

# Restart a deployment
kubectl rollout restart deployment/apigateway -n gridtokenx

# Check rollout status
kubectl rollout status deployment/apigateway -n gridtokenx

# Rollback deployment
kubectl rollout undo deployment/apigateway -n gridtokenx

# Edit deployment
kubectl edit deployment apigateway -n gridtokenx

# Delete all resources
kubectl delete -k overlays/dev/

# Delete namespace (WARNING: deletes everything)
kubectl delete namespace gridtokenx
```

## Production Checklist

Before deploying to production:

- [ ] Update all secrets in `k8s/base/secrets.yaml`
- [ ] Configure external Solana RPC (not local validator)
- [ ] Set up TLS certificates for Ingress
- [ ] Configure proper resource limits
- [ ] Set up monitoring and alerting
- [ ] Configure backup for PostgreSQL
- [ ] Review and adjust HPA settings
- [ ] Configure proper logging aggregation
- [ ] Set up network policies
- [ ] Review security settings
- [ ] Test disaster recovery procedures

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review pod logs: `kubectl logs -n gridtokenx <pod-name>`
3. Check events: `kubectl get events -n gridtokenx`
