#!/bin/bash

# Dry Run Test for Complete Setup Script
# This script tests the setup logic without making actual changes

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

print_status() {
    echo -e "${BLUE}[DRY-RUN]${NC} $1"
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

echo "🧪 Dry Run Test for Complete Setup Script"
echo "========================================="
echo "Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Cluster: $CLUSTER_NAME"
echo "  GitHub User: $GITHUB_USERNAME"
echo

# Test 1: Check if cluster exists
print_step "Testing cluster validation..."
if gcloud container clusters describe $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID &> /dev/null; then
    print_success "Cluster $CLUSTER_NAME exists and is accessible"
else
    print_error "Cluster $CLUSTER_NAME not found"
    exit 1
fi

# Test 2: Check FluxCD installation
print_step "Testing FluxCD check..."
if kubectl get namespace flux-system &> /dev/null && \
   kubectl get deployment -n flux-system source-controller &> /dev/null && \
   kubectl get deployment -n flux-system helm-controller &> /dev/null; then
    print_success "FluxCD is already installed and running"
    FLUXCD_INSTALLED=true
else
    print_warning "FluxCD not fully installed"
    FLUXCD_INSTALLED=false
fi

# Test 3: Check GitHub repositories
print_step "Testing GitHub repository check..."
if curl -s "https://api.github.com/repos/$GITHUB_USERNAME/sample-app-helm-chart" | jq -e '.id' > /dev/null 2>&1; then
    print_success "sample-app-helm-chart repository exists"
    HELM_REPO_EXISTS=true
else
    print_warning "sample-app-helm-chart repository not found"
    HELM_REPO_EXISTS=false
fi

if curl -s "https://api.github.com/repos/$GITHUB_USERNAME/flux-app-delivery" | jq -e '.id' > /dev/null 2>&1; then
    print_success "flux-app-delivery repository exists"
    DELIVERY_REPO_EXISTS=true
else
    print_warning "flux-app-delivery repository not found"
    DELIVERY_REPO_EXISTS=false
fi

# Test 4: Check application deployment
print_step "Testing application deployment check..."
if kubectl get namespace sample-app &> /dev/null; then
    print_success "sample-app namespace exists"
    if kubectl get pods -n sample-app | grep -q Running; then
        print_success "Sample application is running"
        APP_RUNNING=true
    else
        print_warning "Sample application pods not running"
        APP_RUNNING=false
    fi
else
    print_warning "sample-app namespace not found"
    APP_RUNNING=false
fi

# Test 5: Check Terraform directories
print_step "Testing Terraform directory structure..."
if [ -d "../gke-gitops-infra/flux-bootstrap" ]; then
    print_success "flux-bootstrap directory exists"
    if [ -f "../gke-gitops-infra/flux-bootstrap/main.tf" ]; then
        print_success "flux-bootstrap main.tf exists"
    else
        print_error "flux-bootstrap main.tf not found"
    fi
else
    print_error "flux-bootstrap directory not found"
fi

echo
print_step "📊 Current State Summary:"
echo "========================="
echo "  • GKE Cluster: ✅ Running"
echo "  • FluxCD: $([ "$FLUXCD_INSTALLED" = true ] && echo "✅ Installed" || echo "❌ Not installed")"
echo "  • GitHub Repos: $([ "$HELM_REPO_EXISTS" = true ] && [ "$DELIVERY_REPO_EXISTS" = true ] && echo "✅ Both exist" || echo "❌ Missing repos")"
echo "  • Sample App: $([ "$APP_RUNNING" = true ] && echo "✅ Running" || echo "❌ Not running")"
echo

print_step "🎯 What complete-setup.sh would do:"
echo "===================================="
if [ "$FLUXCD_INSTALLED" = false ]; then
    echo "  1. ⚙️  Bootstrap FluxCD using Terraform"
else
    echo "  1. ⏭️  Skip FluxCD bootstrap (already installed)"
fi

if [ "$HELM_REPO_EXISTS" = false ] || [ "$DELIVERY_REPO_EXISTS" = false ]; then
    echo "  2. 📁 Create missing GitHub repositories"
else
    echo "  2. ⏭️  Skip GitHub repo creation (already exist)"
fi

if [ "$APP_RUNNING" = false ]; then
    echo "  3. 🚀 Deploy sample application via GitOps"
else
    echo "  3. ⏭️  Skip app deployment (already running)"
fi

echo "  4. ✅ Validate deployment"
echo "  5. 📋 Display summary"

echo
print_success "🎉 Dry run completed successfully!"
echo "The setup script should work correctly with the current environment."