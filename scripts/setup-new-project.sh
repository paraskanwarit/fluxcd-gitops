#!/bin/bash

# Setup New Project Script
# This script helps you configure the GitOps setup for a different GKE cluster

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to get project details
get_project_details() {
    echo "Setting up GitOps for a new GKE cluster"
    echo "======================================="
    echo
    
    # Get project ID
    echo -n "Enter your GCP Project ID: "
    read PROJECT_ID
    
    # Get region
    echo -n "Enter your GKE cluster region (e.g., us-central1): "
    read REGION
    
    # Get cluster name
    echo -n "Enter your GKE cluster name: "
    read CLUSTER_NAME
    
    # Get GitHub username
    echo -n "Enter your GitHub username: "
    read GITHUB_USERNAME
    
    echo
    print_status "Configuration Summary:"
    echo "  Project ID: $PROJECT_ID"
    echo "  Region: $REGION"
    echo "  Cluster Name: $CLUSTER_NAME"
    echo "  GitHub Username: $GITHUB_USERNAME"
    echo
    
    echo -n "Is this correct? (y/n): "
    read CONFIRM
    
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        print_error "Setup cancelled"
        exit 1
    fi
}

# Function to update configuration files
update_config_files() {
    print_step "Updating configuration files..."
    
    # Update complete-setup.sh
    if [ -f "scripts/complete-setup.sh" ]; then
        sed -i.bak "s/PROJECT_ID=\".*\"/PROJECT_ID=\"$PROJECT_ID\"/" scripts/complete-setup.sh
        sed -i.bak "s/REGION=\".*\"/REGION=\"$REGION\"/" scripts/complete-setup.sh
        sed -i.bak "s/CLUSTER_NAME=\".*\"/CLUSTER_NAME=\"$CLUSTER_NAME\"/" scripts/complete-setup.sh
        sed -i.bak "s/GITHUB_USERNAME=\".*\"/GITHUB_USERNAME=\"$GITHUB_USERNAME\"/" scripts/complete-setup.sh
        print_success "Updated scripts/complete-setup.sh"
    fi
    
    # Update terraform.tfvars
    if [ -f "environments/non-prod/dev/terraform.tfvars" ]; then
        sed -i.bak "s/project_id = \".*\"/project_id = \"$PROJECT_ID\"/" environments/non-prod/dev/terraform.tfvars
        sed -i.bak "s/region = \".*\"/region = \"$REGION\"/" environments/non-prod/dev/terraform.tfvars
        sed -i.bak "s/cluster_name = \".*\"/cluster_name = \"$CLUSTER_NAME\"/" environments/non-prod/dev/terraform.tfvars
        print_success "Updated environments/non-prod/dev/terraform.tfvars"
    fi
    
    # Update variables.tf if it has default values
    if [ -f "environments/non-prod/dev/variables.tf" ]; then
        sed -i.bak "s/default = \".*\"/default = \"$PROJECT_ID\"/" environments/non-prod/dev/variables.tf
        print_success "Updated environments/non-prod/dev/variables.tf"
    fi
}

# Function to validate cluster access
validate_cluster_access() {
    print_step "Validating cluster access..."
    
    # Check if cluster exists
    if ! gcloud container clusters describe $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID &> /dev/null; then
        print_error "GKE cluster $CLUSTER_NAME not found in region $REGION in project $PROJECT_ID"
        echo "Please verify:"
        echo "  1. The cluster name is correct"
        echo "  2. The region is correct"
        echo "  3. You have access to the project"
        echo "  4. The cluster is running"
        exit 1
    fi
    
    print_success "Cluster found successfully"
    
    # Get cluster credentials
    print_status "Getting cluster credentials..."
    gcloud container clusters get-credentials $CLUSTER_NAME \
        --region=$REGION --project=$PROJECT_ID
    
    # Test connectivity
    if ! kubectl get nodes &> /dev/null; then
        print_error "Cannot connect to cluster. Please check your authentication."
        exit 1
    fi
    
    print_success "Successfully connected to cluster"
    
    # Show cluster info
    print_status "Cluster Information:"
    kubectl cluster-info
    kubectl get nodes
}

# Function to check FluxCD status
check_fluxcd_status() {
    print_step "Checking FluxCD status..."
    
    if kubectl get deployment -n flux-system &> /dev/null; then
        print_warning "FluxCD is already installed in this cluster"
        kubectl get deployment -n flux-system
    else
        print_status "FluxCD is not installed. You can bootstrap it using:"
        echo "  1. Copy flux-bootstrap.tf.example to flux-bootstrap.tf"
        echo "  2. Run terraform apply"
        echo "  3. Or run the complete-setup.sh script"
    fi
}

# Function to show next steps
show_next_steps() {
    print_success "Configuration completed successfully!"
    echo
    echo "Next Steps:"
    echo "==========="
    echo "1. Run the complete setup script:"
    echo "   ./scripts/complete-setup.sh"
    echo
    echo "2. Or manually bootstrap FluxCD:"
    echo "   cd environments/non-prod/dev"
    echo "   cp flux-bootstrap.tf.example flux-bootstrap.tf"
    echo "   terraform init"
    echo "   terraform apply"
    echo
    echo "3. Deploy your applications via GitOps"
    echo
    echo "Your configuration is now ready for project: $PROJECT_ID"
    echo "Cluster: $CLUSTER_NAME in region: $REGION"
}

# Main execution
main() {
    # Check prerequisites
    for tool in gcloud kubectl terraform; do
        if ! command -v $tool &> /dev/null; then
            print_error "Required tool not found: $tool"
            exit 1
        fi
    done
    
    # Check GCP authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "GCP authentication required. Please run: gcloud auth login"
        exit 1
    fi
    
    get_project_details
    update_config_files
    validate_cluster_access
    check_fluxcd_status
    show_next_steps
}

# Run main function
main "$@" 