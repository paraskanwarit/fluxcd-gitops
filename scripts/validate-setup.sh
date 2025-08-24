#!/bin/bash

# GitOps Setup Validation Script
# This script validates the current GitOps setup without modifying infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="extreme-gecko-466211-t1"
REGION="us-central1"
CLUSTER_NAME="dev-gke-autopilot"

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

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    for tool in terraform kubectl gcloud git; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install the missing tools and try again."
        exit 1
    fi
    
    # Check GCP authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "GCP authentication required. Please run: gcloud auth login"
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Function to validate GKE cluster
validate_gke_cluster() {
    print_step "Validating GKE cluster..."
    
    # Check if cluster exists
    if ! gcloud container clusters describe $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID &> /dev/null; then
        print_error "GKE cluster $CLUSTER_NAME not found in region $REGION"
        return 1
    fi
    
    print_success "GKE cluster $CLUSTER_NAME found"
    
    # Get cluster credentials
    print_status "Getting cluster credentials..."
    gcloud container clusters get-credentials $CLUSTER_NAME \
        --region=$REGION --project=$PROJECT_ID
    
    # Check cluster nodes
    print_status "Checking cluster nodes..."
    kubectl get nodes
    
    print_success "GKE cluster validation completed"
}

# Function to validate FluxCD
validate_fluxcd() {
    print_step "Validating FluxCD installation..."
    
    # Check if FluxCD namespace exists
    if ! kubectl get namespace flux-system &> /dev/null; then
        print_warning "FluxCD namespace not found. FluxCD may not be installed."
        return 1
    fi
    
    # Check FluxCD deployments
    print_status "Checking FluxCD deployments..."
    kubectl get deployment -n flux-system
    
    # Check FluxCD pods
    print_status "Checking FluxCD pods..."
    kubectl get pods -n flux-system
    
    # Check FluxCD CRDs
    print_status "Checking FluxCD Custom Resource Definitions..."
    kubectl get crd | grep flux
    
    print_success "FluxCD validation completed"
}

# Function to validate application deployment
validate_application() {
    print_step "Validating application deployment..."
    
    # Check if sample-app namespace exists
    if ! kubectl get namespace sample-app &> /dev/null; then
        print_warning "sample-app namespace not found. Application may not be deployed."
        return 1
    fi
    
    # Check application pods
    print_status "Checking application pods..."
    kubectl get pods -n sample-app
    
    # Check application services
    print_status "Checking application services..."
    kubectl get svc -n sample-app
    
    # Check GitOps resources
    print_status "Checking GitOps resources..."
    kubectl get gitrepository -A
    kubectl get helmchart -A
    kubectl get helmrelease -A
    
    print_success "Application validation completed"
}

# Function to test application connectivity
test_application() {
    print_step "Testing application connectivity..."
    
    # Check if application is running
    if ! kubectl get pods -n sample-app -l app=sample-app --field-selector=status.phase=Running | grep -q .; then
        print_warning "Application pods not running. Skipping connectivity test."
        return 1
    fi
    
    # Test application connectivity
    print_status "Testing application connectivity..."
    kubectl port-forward -n sample-app svc/sample-app2-sample-app 8080:80 &
    local port_forward_pid=$!
    
    # Wait for port forward to be ready
    sleep 5
    
    # Test application
    if curl -s http://localhost:8080 | grep -q "Welcome to nginx"; then
        print_success "Application is serving traffic correctly"
    else
        print_warning "Application connectivity test failed"
    fi
    
    # Clean up port forward
    kill $port_forward_pid 2>/dev/null || true
    
    print_success "Application connectivity test completed"
}

# Function to display validation summary
display_summary() {
    echo
    echo "📊 GitOps Setup Validation Summary"
    echo "================================="
    echo
    echo "🔗 Access Information:"
    echo "====================="
    echo "  • GKE Cluster: https://console.cloud.google.com/kubernetes/clusters/details/$REGION/$CLUSTER_NAME?project=$PROJECT_ID"
    echo "  • GitHub Repository: https://github.com/paraskanwarit/fluxcd-gitops"
    echo
    echo "🧪 Validation Commands:"
    echo "======================"
    echo "  • Check cluster: kubectl get nodes"
    echo "  • Check FluxCD: kubectl get deployment -n flux-system"
    echo "  • Check app: kubectl get pods -n sample-app"
    echo "  • Test app: kubectl port-forward -n sample-app svc/sample-app2-sample-app 8080:80"
    echo
    echo "🎭 Demo Commands:"
    echo "================"
    echo "  • Show GitOps flow: kubectl get helmrelease -A"
    echo "  • Show app logs: kubectl logs -n sample-app -l app=sample-app"
    echo "  • Show FluxCD logs: kubectl logs -n flux-system deployment/helm-controller"
    echo
}

# Function to handle cleanup on script exit
cleanup() {
    print_warning "Cleaning up..."
    # Kill any background processes
    jobs -p | xargs -r kill
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    echo "🔍 GitOps Setup Validation"
    echo "=========================="
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Validate GKE cluster
    validate_gke_cluster
    
    # Validate FluxCD
    validate_fluxcd
    
    # Validate application deployment
    validate_application
    
    # Test application connectivity
    test_application
    
    # Display summary
    display_summary
    
    print_success "🎉 Validation completed!"
}

# Run main function
main "$@" 