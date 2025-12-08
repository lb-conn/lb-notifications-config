# LB Notifications Config Repository

GitOps configuration repository for the LB Notifications project using Kustomize and ArgoCD.

## Overview

This repository contains Kubernetes manifests for deploying the LB Notifications worker (`sync-provider-users`) across multiple environments using GitOps principles.

## Structure

```
lb-notifications-config/
├── base/                           # Base Kubernetes manifests
│   ├── kustomization.yaml
│   ├── shared-configmap.yaml
│   ├── shared-external-secret.yaml
│   ├── ghcr-external-secret.yaml
│   └── sync-provider-users-deployment.yaml
├── environments/
│   ├── dev/kustomization.yaml      # DEV environment overlays
│   ├── qa/kustomization.yaml       # QA environment overlays
│   ├── staging/kustomization.yaml  # STAGING environment overlays
│   └── prd/kustomization.yaml      # PRD environment overlays
└── argocd-apps/
    ├── dev.yaml                    # ArgoCD Application for DEV
    ├── qa.yaml                     # ArgoCD Application for QA
    ├── staging.yaml                # ArgoCD Application for STAGING
    └── prd.yaml                    # ArgoCD Application for PRD
```

## Modules

This repository manages the following LB Notifications module:

- **sync-provider-users** - Temporal worker for synchronizing provider users with notification providers (Novu)

## Environments

| Environment | Namespace | Auto-sync | Replicas | Node Selector |
|------------|-----------|-----------|----------|---------------|
| DEV | lb-notifications | ✅ Yes | 1 | role: dev |
| QA | lb-notifications | ✅ Yes | 1 | role: qa |
| STAGING | lb-notifications | ❌ Manual | 1 | role: staging |
| PRD | lb-notifications | ❌ Manual | 2 | role: prd |

## Image Management

Images are automatically updated by GitHub Actions workflows from the [lb-notifications repository](https://github.com/lb-conn/lb-notifications).

**Image naming convention:**
```
ghcr.io/lb-conn/lb-notifications/sync-provider-users:<sha8>
```

Example:
```
ghcr.io/lb-conn/lb-notifications/sync-provider-users:abc12345
```

## Deployment Workflow

### 1. Automatic (DEV)
- Push to `main` branch in lb-notifications repo
- GitHub Actions builds images
- Updates `environments/dev/kustomization.yaml`
- ArgoCD auto-syncs to DEV cluster

### 2. Tag-based (QA)
```bash
# Create QA tag
git tag qa-v1.0.0-$(git rev-parse --short HEAD)
git push origin qa-v1.0.0-$(git rev-parse --short HEAD)
```
- GitHub Actions validates images
- Updates `environments/qa/kustomization.yaml`
- ArgoCD auto-syncs to QA cluster

### 3. Manual (STAGING/PRD)
```bash
# Create STAGING tag
git tag stg-v1.0.0-$(git rev-parse --short HEAD)
git push origin stg-v1.0.0-$(git rev-parse --short HEAD)

# Create PRD tag
git tag prd-v1.0.0-$(git rev-parse --short HEAD)
git push origin prd-v1.0.0-$(git rev-parse --short HEAD)
```
- GitHub Actions updates `environments/staging/kustomization.yaml` or `environments/prd/kustomization.yaml`
- **Manual sync required via ArgoCD**

## Local Testing

### Prerequisites

Install required tools:

```bash
# Install kustomize
brew install kustomize  # macOS
# or
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

# Install kubectl (if not already installed)
brew install kubectl  # macOS

# Install kubeval for manifest validation (optional but recommended)
brew install kubeval  # macOS
# or
wget https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
tar xf kubeval-linux-amd64.tar.gz
sudo mv kubeval /usr/local/bin
```

### Quick Test Commands

```bash
# Build and validate all environments
make validate-all

# Build specific environment
make build-dev
make build-qa
make build-staging
make build-prd

# Validate manifests (syntax and Kubernetes schema)
make validate-dev
make validate-qa
make validate-staging
make validate-prd

# Save rendered manifests to files for inspection
make render-dev
make render-qa
make render-staging
make render-prd
```

### Manual Testing

#### 1. Build Kustomize Manifests

Test that kustomize can build the manifests without errors:

```bash
# Test DEV environment
kustomize build environments/dev

# Test QA environment
kustomize build environments/qa

# Test STAGING environment
kustomize build environments/staging

# Test PRD environment
kustomize build environments/prd
```

#### 2. Validate YAML Syntax

Check for YAML syntax errors:

```bash
# Validate base
kustomize build base > /dev/null && echo "✓ Base is valid"

# Validate all environments
for env in dev qa staging prd; do
  echo "Validating $env..."
  kustomize build environments/$env > /dev/null && echo "✓ $env is valid" || echo "✗ $env has errors"
done
```

#### 3. Validate Kubernetes Manifests

Validate against Kubernetes API schema:

```bash
# Install kubeval if not already installed
# brew install kubeval  # macOS

# Validate DEV
kustomize build environments/dev | kubeval --strict

# Validate all environments
for env in dev qa staging prd; do
  echo "Validating $env with kubeval..."
  kustomize build environments/$env | kubeval --strict
done
```

#### 4. Dry-Run Apply (if connected to cluster)

Test applying manifests without actually deploying:

```bash
# Dry-run DEV environment
kustomize build environments/dev | kubectl apply --dry-run=client -f -

# Dry-run with server-side validation (requires cluster access)
kustomize build environments/dev | kubectl apply --dry-run=server -f -
```

#### 5. Compare Environments

Compare differences between environments:

```bash
# Compare DEV vs QA
diff <(kustomize build environments/dev) <(kustomize build environments/qa)

# Compare QA vs STAGING
diff <(kustomize build environments/qa) <(kustomize build environments/staging)
```

#### 6. Inspect Rendered Manifests

Save rendered manifests to files for detailed inspection:

```bash
# Render DEV to file
kustomize build environments/dev > /tmp/lb-notifications-dev.yaml

# Render all environments
for env in dev qa staging prd; do
  kustomize build environments/$env > /tmp/lb-notifications-$env.yaml
  echo "Rendered $env to /tmp/lb-notifications-$env.yaml"
done

# View specific resource
kustomize build environments/dev | grep -A 20 "kind: Deployment"
```

#### 7. Test with Local Cluster (Optional)

If you have a local Kubernetes cluster (kind, minikube, etc.):

```bash
# Create namespace
kubectl create namespace lb-notifications --dry-run=client -o yaml | kubectl apply -f -

# Apply DEV environment (be careful - this will actually deploy!)
kustomize build environments/dev | kubectl apply -f -

# Check resources
kubectl get all -n lb-notifications

# Clean up
kustomize build environments/dev | kubectl delete -f -
```

### Common Validation Checks

```bash
# Check for common issues
echo "Checking for hardcoded namespaces..."
grep -r "namespace:" base/ | grep -v "#" || echo "✓ No hardcoded namespaces in base"

echo "Checking for image tags..."
kustomize build environments/dev | grep "image:" | head -5

echo "Checking ConfigMap values..."
kustomize build environments/dev | grep -A 30 "kind: ConfigMap"

echo "Checking ExternalSecret paths..."
kustomize build environments/dev | grep -A 10 "kind: ExternalSecret" | grep "key:"
```

### CI/CD Validation

Before committing, run:

```bash
# Full validation suite
make validate-all

# Or manually:
for env in dev qa staging prd; do
  echo "=== Validating $env ==="
  kustomize build environments/$env > /dev/null || exit 1
  kustomize build environments/$env | kubeval --strict || exit 1
  echo "✓ $env passed validation"
done
echo "✓ All environments validated successfully"
```

## ArgoCD Setup

Apply ArgoCD applications to your cluster:

```bash
# Apply DEV application
kubectl apply -f argocd-apps/dev.yaml

# Apply QA application
kubectl apply -f argocd-apps/qa.yaml

# Apply STAGING application
kubectl apply -f argocd-apps/staging.yaml

# Apply PRD application
kubectl apply -f argocd-apps/prd.yaml
```

Verify applications:
```bash
argocd app list | grep lb-notifications
argocd app get lb-notifications-dev
```

## Secrets Management

### Pull Secret (regcred)

Created automatically via ExternalSecret from AWS Secrets Manager:
- **Secret Path**: `/lb-notifications/ghcr-credentials`

### Application Secrets (ExternalSecret)

Managed via AWS Secrets Manager with External Secrets Operator:
- **DEV**: `/lb-notifications/dev/manual-secrets`
- **QA**: `/lb-notifications/qa/manual-secrets`
- **STAGING**: `/lb-notifications/staging/manual-secrets`
- **PRD**: `/lb-notifications/prd/manual-secrets`

Required secrets:
- `PULSAR_API_KEY` - Pulsar API key for authentication
- `NOVU_API_KEY` - Novu API key for notification provider (obtain from Novu dashboard)
- `NOVU_API_URL` - Novu API URL (defaults to self-hosted: `http://novu-api.novu.svc.cluster.local:3000`)

## Configuration

The worker uses the following environment variables (configured via ConfigMap and Secrets):

### Temporal Configuration
- `TEMPORAL_HOST_PORT` - Temporal server address (default: `temporal.temporal.svc.cluster.local:7233`)
- `TEMPORAL_NAMESPACE` - Temporal namespace (default: `provider-notification`)
- `TASK_QUEUE` - Task queue name (default: `novu-sync-queue`)

### Pulsar Configuration
- `PULSAR_URL` - Pulsar broker URL
- `PULSAR_API_KEY` - Pulsar API key (from secret)
- `PULSAR_TOPIC_EVENTS` - Topic for incoming events
- `PULSAR_SUBSCRIPTION_NAME` - Subscription name

### Novu Configuration
- `NOVU_API_KEY` - Novu API key (from secret, obtain from Novu dashboard)
- `NOVU_API_URL` - Novu API URL (from secret, defaults to self-hosted: `http://novu-api.novu.svc.cluster.local`)
- `NOVU_API_PORT`- Novu API PORT (default: `3000`)
- `NOVU_ENABLED` - Enable/disable Novu provider (default: `true`)

**Note:** The Novu self-hosted instance is deployed in the `novu` namespace. To obtain the API key:
1. Access the Novu dashboard: `kubectl port-forward -n novu svc/novu-web 4200:4200`
2. Open `http://localhost:4200` in your browser
3. Create an account (first user becomes admin)
4. Go to **Settings** → **API Keys** and create/copy an API key
5. Add it to AWS Secrets Manager at `/lb-notifications/{env}/manual-secrets`

### Retry Policy
- `RETRY_INITIAL_INTERVAL` - Initial retry interval (default: `1s`)
- `RETRY_MAX_INTERVAL` - Maximum retry interval (default: `5m`)
- `RETRY_BACKOFF_COEFFICIENT` - Exponential backoff coefficient (default: `2.0`)
- `RETRY_WORKFLOW_MAX_ATTEMPTS` - Max workflow attempts (default: `3`)
- `RETRY_ACTIVITY_MAX_ATTEMPTS` - Max activity attempts (default: `5`)

## Monitoring

View deployed resources:

```bash
# List all pods
kubectl get pods -n lb-notifications

# Get deployment status
kubectl get deployments -n lb-notifications

# View logs
kubectl logs -n lb-notifications -l app.kubernetes.io/name=sync-provider-users

# Check ArgoCD sync status
argocd app sync-status lb-notifications-dev
```

## Rollback

### Via ArgoCD
```bash
# List revisions
argocd app history lb-notifications-dev

# Rollback to specific revision
argocd app rollback lb-notifications-dev <revision>
```

### Via Git Tag
```bash
# Create rollback tag
git tag dev-rollback-$(git rev-parse --short <previous-commit>)
git push origin dev-rollback-$(git rev-parse --short <previous-commit>)
```

## Troubleshooting

### Image Pull Errors
```bash
# Verify secret exists
kubectl get secret regcred -n lb-notifications

# Check pod events
kubectl describe pod <pod-name> -n lb-notifications
```

### Sync Issues
```bash
# Force sync
argocd app sync lb-notifications-dev --force

# Sync with prune
argocd app sync lb-notifications-dev --prune
```

### Configuration Errors
```bash
# Validate kustomization
kustomize build environments/dev > /dev/null

# View ArgoCD logs
argocd app logs lb-notifications-dev
```

### Worker Issues
```bash
# Check worker logs
kubectl logs -n lb-notifications -l app.kubernetes.io/name=sync-provider-users --tail=100

# Check Temporal connection
kubectl exec -n lb-notifications <pod-name> -- env | grep TEMPORAL

# Check Pulsar connection
kubectl exec -n lb-notifications <pod-name> -- env | grep PULSAR
```

## Contributing

1. Make changes to base manifests or environment overlays
2. Test locally with kustomize
3. Create PR for review
4. After approval, merge to `main`
5. ArgoCD will auto-sync changes (for DEV/QA)

## Links

- **Main Repository**: https://github.com/lb-conn/lb-notifications
- **Documentation**: See lb-notifications repo `docs/architecture.md`
- **ArgoCD UI**: Contact DevOps for access
- **Monitoring**: Contact DevOps for Grafana/Prometheus links

