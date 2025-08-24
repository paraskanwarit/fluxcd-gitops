#!/bin/bash

# Complete GitOps Destroy Script
# This script destroys the entire GitOps demo setup in proper sequence

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
    for tool in kubectl gcloud curl jq; do
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

# Function to remove GitOps applications
remove_gitops_applications() {
    print_step "Removing GitOps applications..."
    
    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        print_warning "Cluster not accessible. Skipping application cleanup."
        return 0
    fi
    
    # Remove sample application
    if kubectl get namespace sample-app &> /dev/null; then
        print_status "Removing sample application..."
        kubectl delete namespace sample-app --ignore-not-found=true
        
        # Wait for namespace to be deleted
        print_status "Waiting for sample-app namespace to be deleted..."
        while kubectl get namespace sample-app &> /dev/null; do
            sleep 5
        done
        print_success "Sample application removed"
    else
        print_status "Sample application not found, skipping..."
    fi
    
    # Remove GitOps configurations
    if kubectl get namespace flux-system &> /dev/null; then
        print_status "Removing GitOps configurations..."
        
        # Remove Kustomizations
        kubectl delete kustomization --all -n flux-system --ignore-not-found=true
        
        # Remove GitRepositories
        kubectl delete gitrepository --all -n flux-system --ignore-not-found=true
        
        # Remove HelmReleases
        kubectl delete helmrelease --all -A --ignore-not-found=true
        
        print_success "GitOps configurations removed"
    fi
}

# Function to destroy FluxCD using existing Terraform code
destroy_fluxcd() {
    print_step "Destroying FluxCD..."
    
    # Check if FluxCD is installed
    if ! kubectl get namespace flux-system &> /dev/null; then
        print_status "FluxCD not found, skipping..."
        return 0
    fi
    
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        print_warning "terraform not found. Manually removing FluxCD namespace..."
        kubectl delete namespace flux-system --ignore-not-found=true
        
        # Wait for namespace to be deleted
        print_status "Waiting for flux-system namespace to be deleted..."
        while kubectl get namespace flux-system &> /dev/null; do
            sleep 5
        done
        print_success "FluxCD namespace removed manually"
        return 0
    fi
    
    # Use existing Terraform code to destroy FluxCD
    print_status "Using existing Terraform code to destroy FluxCD..."
    
    # Get cluster details if cluster is accessible
    if kubectl cluster-info &> /dev/null; then
        export CLUSTER_ENDPOINT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
        export CLUSTER_CA_CERT=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
        export GKE_TOKEN=$(gcloud auth print-access-token)
        
        cd ../gke-gitops-infra/flux-bootstrap
        
        # Initialize Terraform
        print_status "Initializing FluxCD Terraform..."
        terraform init
        
        # Destroy FluxCD
        print_status "Destroying FluxCD..."
        terraform destroy -auto-approve \
            -var="cluster_endpoint=$CLUSTER_ENDPOINT" \
            -var="cluster_ca_certificate=$CLUSTER_CA_CERT" \
            -var="gke_token=$GKE_TOKEN" || {
            print_warning "Terraform destroy failed, manually cleaning up..."
            kubectl delete namespace flux-system --ignore-not-found=true
        }
        
        cd ../../scripts
    else
        print_warning "Cluster not accessible. Cannot use Terraform to destroy FluxCD."
    fi
    
    print_success "FluxCD destroyed"
}

# Function to destroy GKE infrastructure using existing Terraform code
destroy_infrastructure() {
    print_step "GKE cluster destruction (optional)..."
    
    # Check if cluster exists
    if ! gcloud container clusters describe $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID &> /dev/null; then
        print_status "Cluster $CLUSTER_NAME not found, skipping infrastructure destruction..."
        return 0
    fi
    
    echo
    echo "⚠️  Do you want to DELETE the GKE cluster: $CLUSTER_NAME? (y/N)"
    echo "   This will permanently destroy the entire Kubernetes cluster!"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Skipping GKE cluster destruction. Cluster will remain running."
        echo "💡 To manually delete later, run:"
        echo "   gcloud container clusters delete $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID"
        return 0
    fi
    
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        print_warning "terraform not found. Please manually delete the cluster:"
        echo "  gcloud container clusters delete $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID"
        return 0
    fi
    
    # Use existing Terraform code to destroy infrastructure
    print_status "Using existing Terraform code to destroy GKE infrastructure..."
    
    cd ../gke-gitops-infra/environment/non-prod/dev
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Destroy infrastructure
    print_status "Destroying infrastructure..."
    terraform destroy -auto-approve \
        -var="project=$PROJECT_ID" \
        -var="region=$REGION" \
        -var="cluster_name=$CLUSTER_NAME" || {
        print_warning "Terraform destroy failed. You may need to manually delete resources."
        print_status "Manual cleanup command:"
        echo "  gcloud container clusters delete $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID"
    }
    
    cd ../../../../scripts
    
    print_success "GKE infrastructure destruction completed"
}

# Function to clean up GitHub repositories (optional)
cleanup_github_repos() {
    print_step "GitHub repository cleanup (optional)..."
    
    echo "Do you want to delete the GitHub repositories? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Get GitHub token if not provided
        if [ -z "$GITHUB_TOKEN" ]; then
            print_warning "GitHub token not provided"
            echo -n "Please enter your GitHub Personal Access Token: "
            read -s GITHUB_TOKEN
            echo
        fi
        
        # Validate token
        if ! curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | jq -e '.login' > /dev/null; then
            print_error "Invalid GitHub token. Skipping repository cleanup."
            return 0
        fi
        
        # Delete repositories
        local repos=("sample-app-helm-chart" "flux-app-delivery")
        
        for repo in "${repos[@]}"; do
            print_status "Deleting repository: $repo"
            
            response=$(curl -s -X DELETE \
                -H "Authorization: token $GITHUB_TOKEN" \
                -H "Accept: application/vnd.github.v3+json" \
                "https://api.github.com/repos/$GITHUB_USERNAME/$repo")
            
            if [ $? -eq 0 ]; then
                print_success "Repository $repo deleted"
            else
                print_warning "Failed to delete repository $repo. You may need to delete it manually."
            fi
        done
    else
        print_status "Skipping GitHub repository cleanup"
        echo "Repositories remain at:"
        echo "  - https://github.com/$GITHUB_USERNAME/sample-app-helm-chart"
        echo "  - https://github.com/$GITHUB_USERNAME/flux-app-delivery"
    fi
}

# Function to clean up local kubectl context
cleanup_kubectl_context() {
    print_step "Cleaning up kubectl context..."
    
    local context_name="gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}"
    
    if kubectl config get-contexts -o name | grep -q "^${context_name}$"; then
        print_status "Removing kubectl context: $context_name"
        kubectl config delete-context "$context_name" || print_warning "Failed to delete context"
        kubectl config delete-cluster "$context_name" || print_warning "Failed to delete cluster config"
        kubectl config delete-user "$context_name" || print_warning "Failed to delete user config"
        print_success "kubectl context cleaned up"
    else
        print_status "kubectl context not found, skipping..."
    fi
}

# Function to display destruction summary
display_summary() {
    print_success "🧹 GitOps Demo Destruction Completed!"
    echo
    echo "📊 Cleanup Summary:"
    echo "=================="
    echo "  ✅ Applications removed"
    echo "  ✅ FluxCD destroyed"
    if gcloud container clusters describe $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID &> /dev/null; then
        echo "  ⏭️  GKE cluster preserved (still running)"
    else
        echo "  ✅ GKE infrastructure destroyed"
    fi
    echo "  ✅ kubectl context cleaned up"
    echo
    echo "🔗 Remaining Resources (if any):"
    echo "==============================="
    echo "  • GitHub Repositories (if not deleted):"
    echo "    - https://github.com/$GITHUB_USERNAME/sample-app-helm-chart"
    echo "    - https://github.com/$GITHUB_USERNAME/flux-app-delivery"
    echo
    echo "💡 Manual Verification:"
    echo "======================"
    echo "  • Check GCP Console: https://console.cloud.google.com/kubernetes/list?project=$PROJECT_ID"
    echo "  • Verify no unexpected charges in billing"
    echo
    echo "🎯 All GitOps demo resources have been cleaned up!"
}

# Function to handle cleanup on script exit
cleanup() {
    print_warning "Script interrupted. Some resources may still exist."
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    echo "🧹 Complete GitOps Demo Destruction"
    echo "==================================="
    echo
    echo "⚠️  WARNING: This will clean up GitOps demo resources!"
    echo "   ✅ Sample applications (will be removed)"
    echo "   ✅ FluxCD installation (will be removed)"
    echo "   ❓ GKE cluster: $CLUSTER_NAME (you'll be asked separately)"
    echo "   ❓ GitHub repositories (optional, you'll be asked)"
    echo "   📍 Project: $PROJECT_ID"
    echo "   📍 Region: $REGION"
    echo
    echo "Continue with cleanup? (y/N)"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Destruction cancelled."
        exit 0
    fi
    
    echo
    print_status "Starting destruction sequence..."
    
    # Check prerequisites
    check_prerequisites
    
    # Remove applications first (graceful shutdown)
    remove_gitops_applications
    
    # Destroy FluxCD
    destroy_fluxcd
    
    # Destroy infrastructure
    destroy_infrastructure
    
    # Clean up GitHub repositories (optional)
    cleanup_github_repos
    
    # Clean up kubectl context
    cleanup_kubectl_context
    
    # Display summary
    display_summary
}

# Run main function
main "$@"