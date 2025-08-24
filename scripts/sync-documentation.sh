#!/usr/bin/env bash

# Script to sync documentation to the separate flux-app-delivery repository
# This creates the comprehensive README and diagrams in the GitOps repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

GITHUB_USERNAME="${GITHUB_USERNAME:-paraskanwarit}"
TEMP_DIR="/tmp/flux-app-delivery-sync"

echo "📚 Syncing documentation to flux-app-delivery repository"
echo "======================================================="
echo

# Clean up any existing temp directory
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# Clone the separate repository
print_status "Cloning flux-app-delivery repository..."
git clone https://github.com/$GITHUB_USERNAME/flux-app-delivery.git "$TEMP_DIR"

cd "$TEMP_DIR"

# Create comprehensive README
print_status "Creating comprehensive README..."
cat > README.md << 'EOF'
# Flux App Delivery Repository

This repository contains GitOps configuration manifests for deploying applications to Kubernetes using FluxCD. It serves as the "delivery" layer in a GitOps architecture, defining how applications should be deployed without containing the application code itself.

## 🏗️ Repository Architecture

This repository follows the GitOps pattern where:
- **Infrastructure** is managed separately (gke-gitops-infra repository)
- **Application code & charts** are in separate repositories (sample-app-helm-chart)
- **Deployment configuration** is managed here (flux-app-delivery)

## 📁 Repository Structure

```
flux-app-delivery/
├── README.md                           # This documentation
├── kustomization.yaml                  # Kustomize configuration for Flux
├── namespaces/
│   └── sample-app-namespace.yaml       # Kubernetes namespace definition
├── helmrelease/
│   ├── sample-app-helmrepository.yaml  # GitRepository source definition
│   └── sample-app-helmrelease.yaml     # HelmRelease deployment definition
└── diagrams/                           # Architecture diagrams
    ├── diagram-delivery.md
    ├── diagram-end-to-end.md
    └── diagram-change-workflow.md
```

## 🔧 Kubernetes Objects Explained

### 1. Kustomization (`kustomization.yaml`)

**What it is:** A Kustomize configuration file that defines which Kubernetes manifests to include.

**Why we use it:** Flux uses Kustomize to organize and apply multiple Kubernetes resources as a single unit. This ensures all related objects are deployed together.

### 2. Namespace (`namespaces/sample-app-namespace.yaml`)

**What it is:** A Kubernetes namespace that provides resource isolation and organization.

**Why we use it:** 
- Isolates application resources from other applications
- Provides security boundaries through RBAC
- Enables resource quotas and limits per application
- Makes it easier to manage and clean up application resources

### 3. GitRepository (`helmrelease/sample-app-helmrepository.yaml`)

**What it is:** A Flux Custom Resource that defines a Git repository as a source for Kubernetes manifests or Helm charts.

**Why we use it:**
- Tells Flux where to find the Helm chart source code
- Enables automatic polling for changes in the chart repository
- Provides authentication and access control for private repositories
- Caches chart content locally for faster deployments

**Configuration:**
```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: sample-app-helm-chart        # Reference name used by HelmRelease
  namespace: flux-system              # Must be in flux-system namespace
spec:
  interval: 1m0s                      # Check for changes every minute
  url: https://github.com/paraskanwarit/sample-app-helm-chart.git
  ref:
    branch: main                      # Track the main branch
```

### 4. HelmRelease (`helmrelease/sample-app-helmrelease.yaml`)

**What it is:** A Flux Custom Resource that defines how to deploy a Helm chart to Kubernetes.

**Why we use it:**
- Provides declarative Helm chart deployments
- Enables GitOps workflow for Helm-based applications
- Supports automatic upgrades when chart or values change
- Allows environment-specific value overrides
- Provides rollback capabilities and deployment history

**Configuration:**
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: sample-app2                   # Name of this HelmRelease
  namespace: sample-app               # Target namespace for deployment
spec:
  interval: 5m                        # How often to reconcile
  chart:
    spec:
      chart: charts/sample-app        # Path to chart in repository
      version: "0.1.2"               # Specific chart version to deploy
      sourceRef:
        kind: GitRepository           # Reference to GitRepository object
        name: sample-app-helm-chart   # Name of GitRepository
        namespace: flux-system        # Namespace where GitRepository exists
  values: {}                          # Override chart default values
```

## 🔄 How GitOps Works Here

### 1. Initial Deployment Flow
1. **Flux Source Controller** monitors this repository for changes
2. **Kustomization** tells Flux which manifests to apply
3. **Namespace** is created first to provide deployment target
4. **GitRepository** object tells Flux where to find the Helm chart
5. **HelmRelease** object tells Flux how to deploy the chart
6. **Flux Helm Controller** fetches chart and deploys application

### 2. Change Detection & Updates
1. **Chart Updates**: When developers update the Helm chart repository, Flux detects changes and redeploys
2. **Configuration Updates**: When this repository is updated, Flux applies the new configuration
3. **Automatic Reconciliation**: Flux continuously ensures deployed state matches desired state

## 🚀 Usage Instructions

### Making Changes

#### Option 1: Update Chart Repository
Update values in `sample-app-helm-chart/charts/sample-app/values.yaml`:
```yaml
image:
  tag: "1.22"  # Change image version
replicaCount: 3  # Change replica count
```

#### Option 2: Override via HelmRelease
Update `helmrelease/sample-app-helmrelease.yaml`:
```yaml
spec:
  values:
    image:
      tag: "1.22"
    replicaCount: 3
    resources:
      limits:
        memory: "512Mi"
```

## 🔍 Monitoring & Troubleshooting

### Check Flux Status
```bash
# Check GitRepository status
kubectl get gitrepository -n flux-system

# Check HelmRelease status
kubectl get helmrelease -n sample-app

# View Flux logs
kubectl logs -n flux-system deployment/source-controller
kubectl logs -n flux-system deployment/helm-controller
```

## 🎯 Benefits of This Approach

### Separation of Concerns
- **Infrastructure**: Managed by platform team
- **Application Code**: Managed by development team  
- **Deployment Config**: Managed by DevOps/SRE team

### GitOps Advantages
- **Declarative**: Desired state defined in Git
- **Auditable**: All changes tracked in Git history
- **Recoverable**: Easy rollback via Git revert
- **Secure**: No direct cluster access needed

## 📚 Related Repositories

- **fluxcd-gitops**: Infrastructure and Flux bootstrap
- **sample-app-helm-chart**: Application Helm charts and templates

## 🔗 Useful Commands

```bash
# Watch Flux reconciliation
flux get sources git
flux get helmreleases

# Force reconciliation
flux reconcile source git sample-app-helm-chart
flux reconcile helmrelease sample-app2

# Suspend/resume reconciliation
flux suspend helmrelease sample-app2
flux resume helmrelease sample-app2
```
EOF

# Create simple diagrams
print_status "Creating architecture diagrams..."

mkdir -p diagrams

# Simple delivery flow diagram
cat > diagrams/delivery-flow.md << 'EOF'
# Flux App Delivery - Simple Flow

```mermaid
flowchart LR
    A[📁 GitRepository<br/>sample-app-helmrepository.yaml] --> B[📁 HelmRelease<br/>sample-app-helmrelease.yaml]
    B --> C[🚀 App Deployed<br/>in sample-app namespace]
    
    D[🌐 External Helm Chart<br/>github.com/paraskanwarit/sample-app-helm-chart] --> B
    E[📁 Namespace<br/>sample-app-namespace.yaml] --> C
```

## What Each File Does

**GitRepository:** Tells Flux where to find the Helm chart (external GitHub repo)

**HelmRelease:** Tells Flux how to deploy the chart (version, values, namespace)

**Namespace:** Creates the target namespace for the application

**Result:** Flux automatically deploys the sample app using the external Helm chart
EOF

# Simple change workflow diagram
cat > diagrams/change-workflow.md << 'EOF'
# Simple GitOps Change Workflow

## Scenario 1: Update Application Image

```mermaid
flowchart LR
    A[👨‍💻 Developer] --> B[📝 Edit values.yaml<br/>image: nginx:1.22]
    B --> C[📤 git push]
    C --> D[🔄 Flux detects change<br/>every 1 minute]
    D --> E[⬇️ Flux pulls new chart]
    E --> F[🚀 Deploy to GKE<br/>Rolling update]
    F --> G[✅ App updated<br/>nginx:1.22 running]
```

**Steps:**
1. Developer changes image tag in sample-app-helm-chart repository
2. Git push triggers change detection
3. Flux automatically pulls and deploys the update
4. Application runs with new image version

## Scenario 2: Override via GitOps Config

```mermaid
flowchart LR
    A[👨‍💻 Developer] --> B[📝 Edit HelmRelease<br/>replicaCount: 3]
    B --> C[📤 git push flux-app-delivery]
    C --> D[🔄 Flux detects config change]
    D --> E[⚙️ Apply new values]
    E --> F[📈 Scale deployment]
    F --> G[✅ App scaled<br/>3 replicas running]
```

**Steps:**
1. Developer updates HelmRelease values in flux-app-delivery repository
2. Git push triggers Flux reconciliation
3. Flux applies the configuration override
4. Application scales to desired replica count
EOF

# Check if there are changes to commit
if git diff --quiet && git diff --cached --quiet; then
    print_success "Repository is already up to date!"
else
    # Add and commit changes
    print_status "Committing documentation updates..."
    git add .
    git commit -m "Add comprehensive GitOps documentation and diagrams

✅ Features:
- Comprehensive README with detailed Kubernetes object explanations
- Simple architecture diagrams for easy understanding
- GitOps workflow examples and best practices
- Troubleshooting and monitoring guidance
- Production-grade documentation structure

✅ Content:
- Detailed explanations of GitRepository, HelmRelease, and Namespace objects
- Clear separation of concerns documentation
- Step-by-step change workflow examples
- Useful commands and troubleshooting tips

This documentation enables anyone to understand and work with this
GitOps repository effectively."

    # Push changes
    print_status "Pushing updates to GitHub..."
    git push origin main

    print_success "flux-app-delivery repository updated successfully!"
fi

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo
print_status "✅ Documentation sync completed!"
echo "🌐 View updated repository: https://github.com/$GITHUB_USERNAME/flux-app-delivery"