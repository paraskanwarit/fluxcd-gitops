#!/bin/bash

# Complete GitOps Setup Script
# This script automates the entire GitOps demo setup from infrastructure to application deployment

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
CLUSTER_NAME="gk3-dev-gke-autopilot"
GITHUB_USERNAME="paraskanwarit"
GITHUB_TOKEN=""

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
    for tool in terraform kubectl gcloud git curl jq; do
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
    
    # Check if project exists and is accessible
    if ! gcloud projects describe $PROJECT_ID &> /dev/null; then
        print_error "GCP project $PROJECT_ID not found or not accessible"
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Function to enable required GCP APIs
enable_gcp_apis() {
    print_step "Enabling required GCP APIs..."
    
    local apis=(
        "container.googleapis.com"
        "compute.googleapis.com"
        "iam.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        print_status "Enabling $api..."
        gcloud services enable $api --project=$PROJECT_ID --quiet
    done
    
    print_success "GCP APIs enabled"
}

# Function to deploy GKE infrastructure
deploy_infrastructure() {
    print_step "Deploying GKE infrastructure..."
    
    cd gke-gitops-infra/environment/non-prod/dev
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Planning Terraform deployment..."
    terraform plan -var="project=$PROJECT_ID" \
                   -var="region=$REGION" \
                   -var="cluster_name=$CLUSTER_NAME" \
                   -out=tfplan
    
    # Deploy infrastructure
    print_status "Deploying infrastructure..."
    terraform apply tfplan
    
    # Get cluster credentials
    print_status "Getting cluster credentials..."
    gcloud container clusters get-credentials $CLUSTER_NAME \
        --region=$REGION --project=$PROJECT_ID
    
    cd ../../../..
    
    print_success "GKE infrastructure deployed"
}

# Function to bootstrap FluxCD
bootstrap_fluxcd() {
    print_step "Bootstrapping FluxCD..."
    
    # Get cluster details for FluxCD
    print_status "Getting cluster details..."
    export CLUSTER_ENDPOINT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
    export CLUSTER_CA_CERT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
    export GKE_TOKEN=$(gcloud auth print-access-token)
    
    cd gke-gitops-infra/flux-bootstrap
    
    # Initialize Terraform
    print_status "Initializing FluxCD Terraform..."
    terraform init
    
    # Deploy FluxCD
    print_status "Deploying FluxCD..."
    terraform apply -auto-approve \
        -var="cluster_endpoint=$CLUSTER_ENDPOINT" \
        -var="cluster_ca_certificate=$CLUSTER_CA_CERT" \
        -var="gke_token=$GKE_TOKEN"
    
    cd ../../..
    
    # Wait for FluxCD to be ready
    print_status "Waiting for FluxCD to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=flux -n flux-system --timeout=300s
    
    print_success "FluxCD bootstrapped successfully"
}

# Function to setup GitHub repositories
setup_github_repos() {
    print_step "Setting up GitHub repositories..."
    
    # Get GitHub token if not provided
    if [ -z "$GITHUB_TOKEN" ]; then
        print_warning "GitHub token not provided"
        echo -n "Please enter your GitHub Personal Access Token: "
        read -s GITHUB_TOKEN
        echo
    fi
    
    # Validate token
    if ! curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | jq -e '.login' > /dev/null; then
        print_error "Invalid GitHub token"
        exit 1
    fi
    
    # Create repositories using the setup script
    cd scripts
    GITHUB_TOKEN=$GITHUB_TOKEN ./setup-github-repos.sh
    cd ..
    
    print_success "GitHub repositories setup completed"
}

# Function to deploy application via GitOps
deploy_application() {
    print_step "Deploying application via GitOps..."
    
    cd flux-app-delivery
    
    # Apply FluxCD manifests
    print_status "Applying FluxCD manifests..."
    kubectl apply -f namespaces/sample-app-namespace.yaml
    kubectl apply -f helmrelease/sample-app-helmrepository.yaml
    kubectl apply -f helmrelease/sample-app-helmrelease.yaml
    
    cd ..
    
    # Wait for application to be deployed
    print_status "Waiting for application deployment..."
    kubectl wait --for=condition=ready pod -l app=sample-app -n sample-app --timeout=300s
    
    print_success "Application deployed via GitOps"
}

# Function to validate deployment
validate_deployment() {
    print_step "Validating deployment..."
    
    # Check infrastructure
    print_status "Checking GKE cluster..."
    kubectl get nodes
    
    # Check FluxCD
    print_status "Checking FluxCD..."
    kubectl get deployment -n flux-system
    
    # Check application
    print_status "Checking application..."
    kubectl get pods -n sample-app
    kubectl get svc -n sample-app
    
    # Check GitOps resources
    print_status "Checking GitOps resources..."
    kubectl get gitrepository -A
    kubectl get helmchart -A
    kubectl get helmrelease -A
    
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
    
    print_success "Deployment validation completed"
}

# Function to display final summary
display_summary() {
    print_success "🎉 GitOps Demo Setup Completed Successfully!"
    echo
    echo "📊 Deployment Summary:"
    echo "====================="
    echo "  • GKE Cluster: $CLUSTER_NAME"
    echo "  • Region: $REGION"
    echo "  • Project: $PROJECT_ID"
    echo "  • FluxCD Version: v2.12.2"
    echo "  • Application: NGINX sample app"
    echo
    echo "🔗 Access Information:"
    echo "====================="
    echo "  • GKE Cluster: https://console.cloud.google.com/kubernetes/clusters/details/$REGION/$CLUSTER_NAME?project=$PROJECT_ID"
    echo "  • GitHub Repositories:"
    echo "    - https://github.com/$GITHUB_USERNAME/sample-app-helm-chart"
    echo "    - https://github.com/$GITHUB_USERNAME/flux-app-delivery"
    echo
    echo "🧪 Testing Commands:"
    echo "==================="
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
    echo "🚀 Your GitOps pipeline is ready for demos!"
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
    echo "🚀 Complete GitOps Demo Setup"
    echo "============================"
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Enable GCP APIs
    enable_gcp_apis
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Bootstrap FluxCD
    bootstrap_fluxcd
    
    # Setup GitHub repositories
    setup_github_repos
    
    # Deploy application
    deploy_application
    
    # Validate deployment
    validate_deployment
    
    # Display summary
    display_summary
}

# Run main function
main "$@" 