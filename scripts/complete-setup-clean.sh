#!/usr/bin/env bash

# Complete GitOps Setup Script - Production Grade with Separate Repositories
# This script automates the GitOps demo setup using separate repositories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration - Auto-detect from current context if possible
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || echo 'extreme-gecko-466211-t1')}"
REGION="${REGION:-us-central1}"
CLUSTER_NAME="${CLUSTER_NAME:-dev-gke-autopilot}"
GITHUB_USERNAME="${GITHUB_USERNAME:-paraskanwarit}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# Try to detect cluster name from current kubectl context
if kubectl config current-context &> /dev/null; then
    CURRENT_CONTEXT=$(kubectl config current-context)
    if [[ $CURRENT_CONTEXT == gke_* ]]; then
        # Extract cluster name from GKE context format: gke_PROJECT_REGION_CLUSTER
        DETECTED_CLUSTER=$(echo $CURRENT_CONTEXT | cut -d'_' -f4)
        if [ ! -z "$DETECTED_CLUSTER" ]; then
            CLUSTER_NAME="$DETECTED_CLUSTER"
        fi
    fi
fi

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Function to validate existing cluster
validate_existing_cluster() {
    print_step "Validating existing GKE cluster..."
    
    # Check if cluster exists
    if gcloud container clusters describe $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID &> /dev/null; then
        print_status "Cluster $CLUSTER_NAME found in project $PROJECT_ID"
        
        # Get cluster credentials
        print_status "Getting cluster credentials..."
        gcloud container clusters get-credentials $CLUSTER_NAME \
            --region=$REGION --project=$PROJECT_ID
        
        print_success "Successfully connected to existing GKE cluster"
        
        # Display cluster info
        print_status "Cluster Information:"
        kubectl cluster-info
        kubectl get nodes
        
        return 0
    else
        print_error "Cluster $CLUSTER_NAME not found in region $REGION"
        return 1
    fi
}

# Function to check if FluxCD is installed
check_fluxcd_installation() {
    if kubectl get deployment -n flux-system source-controller &> /dev/null && \
       kubectl get deployment -n flux-system helm-controller &> /dev/null && \
       kubectl get deployment -n flux-system kustomize-controller &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to bootstrap FluxCD using Terraform
bootstrap_fluxcd_terraform() {
    print_step "Bootstrapping FluxCD using Terraform..."
    
    # Check if FluxCD is already properly installed
    if check_fluxcd_installation; then
        print_success "FluxCD is already installed and running"
        kubectl get deployment -n flux-system
        return 0
    fi
    
    print_status "FluxCD not found. Installing using Terraform..."
    
    # Navigate to flux-bootstrap directory
    if [ ! -d "gke-gitops-infra/flux-bootstrap" ]; then
        print_error "flux-bootstrap directory not found"
        return 1
    fi
    
    cd gke-gitops-infra/flux-bootstrap
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan the deployment
    print_status "Planning FluxCD deployment..."
    terraform plan \
        -var="project_id=$PROJECT_ID" \
        -var="region=$REGION" \
        -var="cluster_name=$CLUSTER_NAME" \
        -var="github_username=$GITHUB_USERNAME" \
        -var="github_token=$GITHUB_TOKEN"
    
    # Apply the deployment
    print_status "Applying FluxCD deployment..."
    terraform apply -auto-approve \
        -var="project_id=$PROJECT_ID" \
        -var="region=$REGION" \
        -var="cluster_name=$CLUSTER_NAME" \
        -var="github_username=$GITHUB_USERNAME" \
        -var="github_token=$GITHUB_TOKEN"
    
    cd ../..
    
    # Wait for FluxCD to be ready
    print_status "Waiting for FluxCD controllers to be ready..."
    kubectl wait --for=condition=available deployment/source-controller -n flux-system --timeout=300s
    kubectl wait --for=condition=available deployment/helm-controller -n flux-system --timeout=300s
    kubectl wait --for=condition=available deployment/kustomize-controller -n flux-system --timeout=300s
    
    print_success "FluxCD successfully bootstrapped!"
    kubectl get deployment -n flux-system
}

# Function to setup GitOps delivery using separate repository
setup_gitops_delivery() {
    print_step "Setting up GitOps delivery using separate repository..."
    
    # Configure FluxCD to watch the separate flux-app-delivery repository
    print_status "Creating GitRepository for flux-app-delivery..."
    kubectl apply -f - <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: flux-app-delivery
  namespace: flux-system
spec:
  interval: 1m0s
  url: https://github.com/$GITHUB_USERNAME/flux-app-delivery.git
  ref:
    branch: main
EOF

    # Configure FluxCD to deploy everything from the separate repository
    print_status "Creating Kustomization for automatic deployment..."
    kubectl apply -f - <<EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: flux-app-delivery
  namespace: flux-system
spec:
  interval: 5m0s
  path: "./"
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-app-delivery
  postBuild:
    substitute:
      GITHUB_USERNAME: "$GITHUB_USERNAME"
EOF

    # Wait for GitRepository to be ready
    print_status "Waiting for GitRepository to sync..."
    kubectl wait --for=condition=ready gitrepository/flux-app-delivery -n flux-system --timeout=300s
    
    # Wait for Kustomization to be ready
    print_status "Waiting for Kustomization to deploy resources..."
    kubectl wait --for=condition=ready kustomization/flux-app-delivery -n flux-system --timeout=300s
    
    # Wait for the sample-app namespace to be created by FluxCD
    print_status "Waiting for sample-app namespace to be created..."
    for i in {1..30}; do
        if kubectl get namespace sample-app &> /dev/null; then
            print_success "sample-app namespace created successfully"
            break
        fi
        echo "Waiting for namespace... ($i/30)"
        sleep 10
    done
    
    if ! kubectl get namespace sample-app &> /dev/null; then
        print_warning "sample-app namespace not created yet. Checking FluxCD status..."
        kubectl get kustomization -n flux-system
        kubectl describe kustomization flux-app-delivery -n flux-system
        return 1
    fi
    
    print_success "GitOps delivery configured successfully!"
}

# Function to validate deployment
validate_deployment() {
    print_step "Validating deployment..."
    
    # Check FluxCD status
    print_status "Checking FluxCD status..."
    kubectl get deployment -n flux-system
    
    # Check GitRepository status
    print_status "Checking GitRepository status..."
    kubectl get gitrepository -n flux-system
    
    # Check Kustomization status
    print_status "Checking Kustomization status..."
    kubectl get kustomization -n flux-system
    
    # Check HelmRelease status
    print_status "Checking HelmRelease status..."
    kubectl get helmrelease -n sample-app
    
    # Check application pods
    print_status "Checking application pods..."
    kubectl get pods -n sample-app
    
    # Wait for application to be ready
    print_status "Waiting for application to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sample-app -n sample-app --timeout=300s
    
    print_success "Deployment validation completed!"
}

# Function to display final summary
display_summary() {
    echo
    echo "🎉 GitOps Setup Complete!"
    echo "========================="
    echo
    echo "✅ Production-Grade Architecture:"
    echo "  📁 Infrastructure: https://github.com/$GITHUB_USERNAME/fluxcd-gitops"
    echo "  📁 GitOps Config:  https://github.com/$GITHUB_USERNAME/flux-app-delivery"
    echo "  📁 Helm Charts:    https://github.com/$GITHUB_USERNAME/sample-app-helm-chart"
    echo
    echo "✅ Deployment Details:"
    echo "  🏗️  GKE Cluster: $CLUSTER_NAME"
    echo "  🌍  Region: $REGION"
    echo "  🔄  FluxCD: Installed and monitoring"
    echo "  🚀  Sample App: Deployed via GitOps"
    echo
    echo "🔍 Verification Commands:"
    echo "  kubectl get nodes"
    echo "  kubectl get deployment -n flux-system"
    echo "  kubectl get helmrelease -n sample-app"
    echo "  kubectl get pods -n sample-app"
    echo
    echo "🎯 Demo Flow:"
    echo "  1. Show separate repository architecture"
    echo "  2. Make changes to sample-app-helm-chart"
    echo "  3. Watch Flux automatically deploy updates"
    echo "  4. Show GitOps configuration overrides"
    echo
    echo "🌐 Access URLs:"
    echo "  GKE Console: https://console.cloud.google.com/kubernetes/clusters/details/$REGION/$CLUSTER_NAME?project=$PROJECT_ID"
    echo
    print_success "Ready for production-grade GitOps demo! 🚀"
}

# Main execution
main() {
    echo "🚀 Complete GitOps Setup - Production Grade"
    echo "==========================================="
    echo
    echo "Configuration:"
    echo "  Project ID: $PROJECT_ID"
    echo "  Region: $REGION"
    echo "  Cluster: $CLUSTER_NAME"
    echo "  GitHub User: $GITHUB_USERNAME"
    echo
    
    # Validate existing cluster
    if ! validate_existing_cluster; then
        print_error "Cluster validation failed. Please ensure the cluster exists."
        exit 1
    fi
    
    # Bootstrap FluxCD
    if ! bootstrap_fluxcd_terraform; then
        print_error "FluxCD bootstrap failed."
        exit 1
    fi
    
    # Setup GitOps delivery
    if ! setup_gitops_delivery; then
        print_error "GitOps delivery setup failed."
        exit 1
    fi
    
    # Validate deployment
    if ! validate_deployment; then
        print_warning "Deployment validation had issues, but continuing..."
    fi
    
    # Display summary
    display_summary
}

# Run main function
main "$@"