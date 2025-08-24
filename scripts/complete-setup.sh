#!/usr/bin/env bash

# Complete GitOps Setup Script
# This script automates the GitOps demo setup using existing GKE infrastructure

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

# Function to validate existing GKE cluster
validate_existing_cluster() {
    print_step "Validating existing GKE cluster..."
<<<<<<< HEAD
    
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
        print_warning "Cluster $CLUSTER_NAME not found in region $REGION"
        return 1
    fi
}

# Function to deploy infrastructure using existing Terraform code
deploy_infrastructure_terraform() {
    print_status "Deploying GKE infrastructure using existing Terraform code..."
    
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        print_error "terraform not found. Please install it first."
        return 1
    fi
=======
>>>>>>> d50a66fd9755ba0fe8b3b9c7a10d410fd719bab0
    
    # Check if cluster exists
    if ! gcloud container clusters describe $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID &> /dev/null; then
        print_error "GKE cluster $CLUSTER_NAME not found in region $REGION"
        exit 1
    fi
    
<<<<<<< HEAD
    # Clean up any existing Terraform state that might be using old module source
    if [ -d ".terraform" ]; then
        print_status "Cleaning up existing Terraform state..."
        rm -rf .terraform .terraform.lock.hcl
    fi
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Planning Terraform deployment..."
    if terraform plan -var="project=$PROJECT_ID" \
                      -var="region=$REGION" \
                      -var="cluster_name=$CLUSTER_NAME" \
                      -out=tfplan; then
        # Deploy infrastructure
        print_status "Deploying infrastructure..."
        terraform apply tfplan
    else
        print_error "Terraform plan failed"
        cd ../../../..
        return 1
    fi
=======
    print_status "Cluster $CLUSTER_NAME found in project $PROJECT_ID"
>>>>>>> d50a66fd9755ba0fe8b3b9c7a10d410fd719bab0
    
    # Get cluster credentials
    print_status "Getting cluster credentials..."
    gcloud container clusters get-credentials $CLUSTER_NAME \
        --region=$REGION --project=$PROJECT_ID
    
    # Verify cluster connectivity
    if ! kubectl get nodes &> /dev/null; then
        print_error "Cannot connect to cluster. Please check your authentication."
        exit 1
    fi
    
<<<<<<< HEAD
    return 0
=======
    print_success "Successfully connected to existing GKE cluster"
    
    # Display cluster info
    print_status "Cluster Information:"
    kubectl cluster-info
    kubectl get nodes
>>>>>>> d50a66fd9755ba0fe8b3b9c7a10d410fd719bab0
}

# Function to deploy GKE infrastructure
deploy_infrastructure() {
    print_step "Deploying GKE infrastructure..."
    
    if deploy_infrastructure_terraform; then
        print_success "GKE infrastructure deployed successfully"
    else
        print_error "Failed to deploy GKE infrastructure"
        exit 1
    fi
}

# Function to check if FluxCD is properly installed
check_fluxcd_installation() {
    print_status "Checking FluxCD installation..."
    
    # Check if flux-system namespace exists
    if ! kubectl get namespace flux-system &> /dev/null; then
        return 1
    fi
    
    # Check if CRDs are properly installed
    if ! kubectl get crd gitrepositories.source.toolkit.fluxcd.io &> /dev/null || \
       ! kubectl get crd helmreleases.helm.toolkit.fluxcd.io &> /dev/null; then
        return 1
    fi
    
    # Check if controllers are running
    if ! kubectl get deployment -n flux-system source-controller &> /dev/null || \
       ! kubectl get deployment -n flux-system helm-controller &> /dev/null || \
       ! kubectl get deployment -n flux-system kustomize-controller &> /dev/null; then
        return 1
    fi
    
    # Check if deployments are ready
    if ! kubectl wait --for=condition=available deployment/source-controller -n flux-system --timeout=30s &> /dev/null || \
       ! kubectl wait --for=condition=available deployment/helm-controller -n flux-system --timeout=30s &> /dev/null || \
       ! kubectl wait --for=condition=available deployment/kustomize-controller -n flux-system --timeout=30s &> /dev/null; then
        return 1
    fi
    
    return 0
}

# Function to bootstrap FluxCD using existing Terraform code
bootstrap_fluxcd() {
    print_step "Bootstrapping FluxCD..."
    
<<<<<<< HEAD
    # Check if FluxCD is already properly installed
    if check_fluxcd_installation; then
        print_success "FluxCD is already properly installed and running"
        return 0
    fi
    
    # If FluxCD namespace exists but installation is incomplete, clean it up
    if kubectl get namespace flux-system &> /dev/null; then
        print_warning "FluxCD namespace exists but installation is incomplete. Cleaning up..."
        kubectl delete namespace flux-system --ignore-not-found=true
        # Wait for namespace to be fully deleted
        while kubectl get namespace flux-system &> /dev/null; do
            print_status "Waiting for flux-system namespace to be deleted..."
            sleep 5
        done
    fi
    
    # Use existing Terraform code to install FluxCD
    print_status "Using existing Terraform code to install FluxCD..."
    
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        print_error "terraform not found. Please install it first."
        exit 1
    fi
    
    # Get cluster details
    print_status "Getting cluster details..."
    export CLUSTER_ENDPOINT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
    export CLUSTER_CA_CERT=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
    export GKE_TOKEN=$(gcloud auth print-access-token)
    
    # Validate cluster details
    if [ -z "$CLUSTER_ENDPOINT" ] || [ -z "$CLUSTER_CA_CERT" ] || [ -z "$GKE_TOKEN" ]; then
        print_error "Failed to get cluster details. Make sure you're connected to the cluster."
        exit 1
    fi
    
    cd gke-gitops-infra/flux-bootstrap
=======
    # Check if FluxCD is already installed
    if kubectl get deployment -n flux-system &> /dev/null; then
        print_warning "FluxCD appears to be already installed. Skipping bootstrap."
        return 0
    fi
    
    # Check if we're in the right directory
    if [ ! -d "environments/non-prod/dev" ]; then
        print_error "Please run this script from the das-l4-infra-np repository root"
        exit 1
    fi
    
    cd environments/non-prod/dev
    
    # Check if flux-bootstrap.tf exists, if not, copy from example
    if [ ! -f "flux-bootstrap.tf" ]; then
        print_status "Setting up FluxCD bootstrap..."
        cp flux-bootstrap.tf.example flux-bootstrap.tf
        print_warning "FluxCD bootstrap enabled. Run 'terraform apply' to install FluxCD."
        print_warning "Or run this script again after FluxCD is installed to continue with app deployment."
        cd ../../..
        return 0
    fi
>>>>>>> d50a66fd9755ba0fe8b3b9c7a10d410fd719bab0
    
    # Initialize Terraform
    print_status "Initializing FluxCD Terraform..."
    terraform init
    
    # Deploy FluxCD
    print_status "Deploying FluxCD..."
    terraform apply -auto-approve
    
    cd ../../..
    
    # Wait for FluxCD to be ready
    print_status "Waiting for FluxCD controllers to be ready..."
    kubectl wait --for=condition=available deployment/source-controller -n flux-system --timeout=300s
    kubectl wait --for=condition=available deployment/helm-controller -n flux-system --timeout=300s
    kubectl wait --for=condition=available deployment/kustomize-controller -n flux-system --timeout=300s
    
    # Verify CRDs are installed
    print_status "Verifying FluxCD CRDs..."
    kubectl get crd gitrepositories.source.toolkit.fluxcd.io
    kubectl get crd helmreleases.helm.toolkit.fluxcd.io
    
    print_success "FluxCD bootstrapped successfully using existing Terraform code"
}

# Function to check if GitHub repositories exist
check_github_repos() {
    print_status "Checking GitHub repositories..."
    
    # Check if repositories already exist
    if curl -s "https://api.github.com/repos/$GITHUB_USERNAME/sample-app-helm-chart" | jq -e '.id' > /dev/null 2>&1; then
        print_warning "GitHub repositories already exist. Skipping creation."
        return 0
    fi
    
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
        return 1
    fi
    
<<<<<<< HEAD
    # Check if both repositories exist
    if curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$GITHUB_USERNAME/sample-app-helm-chart" | jq -e '.name' > /dev/null 2>&1 && \
       curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$GITHUB_USERNAME/flux-app-delivery" | jq -e '.name' > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to setup GitHub repositories
setup_github_repos() {
    print_step "Setting up GitHub repositories..."
    
    # Check if repositories already exist
    if check_github_repos; then
        print_success "GitHub repositories already exist and are accessible"
        return 0
    fi
    
    print_status "GitHub repositories not found or not accessible. Creating them..."
    
    # Use existing setup script
    cd scripts
    GITHUB_TOKEN=$GITHUB_TOKEN ./setup-github-repos.sh
    cd ..
=======
    # Create repositories using the setup script
    if [ -f "scripts/setup-github-repos.sh" ]; then
        cd scripts
        GITHUB_TOKEN=$GITHUB_TOKEN ./setup-github-repos.sh
        cd ..
    else
        print_warning "GitHub setup script not found. Please create repositories manually."
    fi
>>>>>>> d50a66fd9755ba0fe8b3b9c7a10d410fd719bab0
    
    # Verify repositories were created successfully
    if check_github_repos; then
        print_success "GitHub repositories setup completed successfully"
    else
        print_error "Failed to setup GitHub repositories"
        exit 1
    fi
}

# Function to configure FluxCD to watch and deploy from Git repositories
deploy_application() {
    print_step "Configuring GitOps deployment..."
    
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
    timeout=120
    while [ $timeout -gt 0 ]; do
        if kubectl get namespace sample-app &> /dev/null; then
            break
        fi
        sleep 5
        timeout=$((timeout - 5))
    done
    
    if [ $timeout -le 0 ]; then
        print_warning "sample-app namespace not created yet. Checking FluxCD status..."
        kubectl get kustomization -n flux-system
        kubectl describe kustomization flux-app-delivery -n flux-system
        return 1
    fi
    
    # Wait for application to be deployed by FluxCD
    print_status "Waiting for application to be deployed by FluxCD..."
    
    # Wait for HelmRelease to be ready first
    kubectl wait --for=condition=ready helmrelease/sample-app2 -n sample-app --timeout=300s
    
    # Then wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app=sample-app -n sample-app --timeout=300s
    
    print_success "Application deployed automatically via GitOps!"
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
    
    # Start port-forward in background and capture PID
    kubectl port-forward -n sample-app svc/sample-app2-sample-app 8080:80 > /dev/null 2>&1 &
    local port_forward_pid=$!
    
    # Wait for port forward to be ready
    print_status "Waiting for port-forward to establish..."
    sleep 10
    
    # Test application
    if curl -s --max-time 10 http://localhost:8080 | grep -q "Welcome to nginx"; then
        print_success "Application is serving traffic correctly"
    else
        print_warning "Application connectivity test failed - checking if port-forward is working"
        if netstat -an | grep -q ":8080.*LISTEN"; then
            print_status "Port 8080 is listening, but application test failed"
        else
            print_warning "Port-forward may not be working correctly"
        fi
    fi
    
    # Clean up port forward
    if [ -n "$port_forward_pid" ]; then
        kill $port_forward_pid 2>/dev/null || true
        wait $port_forward_pid 2>/dev/null || true
    fi
    
    print_success "Deployment validation completed"
}

# Function to display final summary
display_summary() {
    print_success "GitOps Demo Setup Completed Successfully!"
    echo
    echo "Deployment Summary:"
    echo "=================="
    echo "  GKE Cluster: $CLUSTER_NAME (existing)"
    echo "  Region: $REGION"
    echo "  Project: $PROJECT_ID"
    echo "  FluxCD Version: v2.12.2"
    echo "  Application: NGINX sample app"
    echo
    echo "Access Information:"
    echo "=================="
    echo "  GKE Cluster: https://console.cloud.google.com/kubernetes/clusters/details/$REGION/$CLUSTER_NAME?project=$PROJECT_ID"
    echo "  GitHub Repositories:"
    echo "    - https://github.com/$GITHUB_USERNAME/sample-app-helm-chart"
    echo "    - https://github.com/$GITHUB_USERNAME/flux-app-delivery"
    echo
    echo "Testing Commands:"
    echo "================="
    echo "  Check cluster: kubectl get nodes"
    echo "  Check FluxCD: kubectl get deployment -n flux-system"
    echo "  Check app: kubectl get pods -n sample-app"
    echo "  Test app: kubectl port-forward -n sample-app svc/sample-app2-sample-app 8080:80"
    echo
    echo "Demo Commands:"
    echo "=============="
    echo "  Show GitOps flow: kubectl get helmrelease -A"
    echo "  Show app logs: kubectl logs -n sample-app -l app=sample-app"
    echo "  Show FluxCD logs: kubectl logs -n flux-system deployment/helm-controller"
    echo
    echo "Your GitOps pipeline is ready for demos!"
}

# Function to handle cleanup on script exit
cleanup() {
    print_warning "Cleaning up..."
    # Kill any background processes
    jobs -p | xargs -r kill 2>/dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
<<<<<<< HEAD
    echo "🚀 Complete GitOps Demo Setup (Using Existing Infrastructure)"
=======
    echo "Complete GitOps Demo Setup (Using Existing Infrastructure)"
>>>>>>> d50a66fd9755ba0fe8b3b9c7a10d410fd719bab0
    echo "========================================================"
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Enable GCP APIs
    enable_gcp_apis
    
<<<<<<< HEAD
    # Validate existing infrastructure or deploy new
    if ! validate_existing_cluster; then
        deploy_infrastructure
    fi
=======
    # Validate existing cluster
    validate_existing_cluster
>>>>>>> d50a66fd9755ba0fe8b3b9c7a10d410fd719bab0
    
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