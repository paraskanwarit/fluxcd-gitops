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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -p, --project PROJECT_ID     GCP Project ID"
    echo "  -r, --region REGION         GKE cluster region"
    echo "  -c, --cluster CLUSTER_NAME  GKE cluster name"
    echo "  -g, --github USERNAME       GitHub username"
    echo "  -e, --environment ENV       Environment name (dev, staging, prod)"
    echo "  -f, --force                 Force overwrite existing configuration"
    echo "  -h, --help                  Show this help message"
    echo
    echo "Examples:"
    echo "  $0 -p my-project -r us-west1 -c prod-cluster -g myusername"
    echo "  $0 --project my-project --region us-west1 --cluster prod-cluster"
    echo "  $0  # Interactive mode"
    echo
}

# Function to get project details interactively
get_project_details_interactive() {
    echo "Setting up GitOps for a new GKE cluster"
    echo "======================================="
    echo
    
    # Get project ID
    echo -n "Enter your GCP Project ID: "
    read PROJECT_ID
    
    # Get region
    echo -n "Enter your GKE cluster region (e.g., us-central1, us-west1, europe-west1): "
    read REGION
    
    # Get cluster name
    echo -n "Enter your GKE cluster name: "
    read CLUSTER_NAME
    
    # Get GitHub username
    echo -n "Enter your GitHub username: "
    read GITHUB_USERNAME
    
    # Get environment name
    echo -n "Enter environment name (dev, staging, prod) [default: dev]: "
    read ENVIRONMENT
    ENVIRONMENT=${ENVIRONMENT:-dev}
    
    echo
    print_status "Configuration Summary:"
    echo "  Project ID: $PROJECT_ID"
    echo "  Region: $REGION"
    echo "  Cluster Name: $CLUSTER_NAME"
    echo "  GitHub Username: $GITHUB_USERNAME"
    echo "  Environment: $ENVIRONMENT"
    echo
    
    echo -n "Is this correct? (y/n): "
    read CONFIRM
    
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        print_error "Setup cancelled"
        exit 1
    fi
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--project)
                PROJECT_ID="$2"
                shift 2
                ;;
            -r|--region)
                REGION="$2"
                shift 2
                ;;
            -c|--cluster)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            -g|--github)
                GITHUB_USERNAME="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -f|--force)
                FORCE_OVERWRITE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if all required variables are set
    if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ] || [ -z "$CLUSTER_NAME" ] || [ -z "$GITHUB_USERNAME" ]; then
        print_warning "Some required variables are missing, switching to interactive mode"
        get_project_details_interactive
    fi
    
    # Set default environment if not specified
    ENVIRONMENT=${ENVIRONMENT:-dev}
}

# Function to create environment directory structure
create_environment_structure() {
    print_step "Creating environment directory structure..."
    
    # Create environment directory if it doesn't exist
    ENV_DIR="environments/non-prod/$ENVIRONMENT"
    if [ "$ENVIRONMENT" = "prod" ]; then
        ENV_DIR="environments/prod/$ENVIRONMENT"
    fi
    
    if [ ! -d "$ENV_DIR" ]; then
        print_status "Creating environment directory: $ENV_DIR"
        mkdir -p "$ENV_DIR"
    fi
    
    # Copy template files
    if [ ! -f "$ENV_DIR/main.tf" ] || [ "$FORCE_OVERWRITE" = true ]; then
        print_status "Copying Terraform configuration files..."
        cp environments/non-prod/dev/main.tf "$ENV_DIR/"
        cp environments/non-prod/dev/variables.tf "$ENV_DIR/"
        cp environments/non-prod/dev/backend.tf "$ENV_DIR/"
        cp environments/non-prod/dev/flux-bootstrap.tf.example "$ENV_DIR/"
        print_success "Configuration files copied to $ENV_DIR"
    else
        print_warning "Environment directory already exists. Use -f to force overwrite."
    fi
}

# Function to update configuration files
update_config_files() {
    print_step "Updating configuration files..."
    
    ENV_DIR="environments/non-prod/$ENVIRONMENT"
    if [ "$ENVIRONMENT" = "prod" ]; then
        ENV_DIR="environments/prod/$ENVIRONMENT"
    fi
    
    # Update terraform.tfvars
    if [ -f "$ENV_DIR/terraform.tfvars" ] || [ "$FORCE_OVERWRITE" = true ]; then
        cat > "$ENV_DIR/terraform.tfvars" << EOF
# Configuration for existing GKE cluster
# These values are used by data sources to fetch cluster information

project_id = "$PROJECT_ID"
region     = "$REGION"
cluster_name = "$CLUSTER_NAME"

# FluxCD Configuration
flux_version = "2.12.2"
EOF
        print_success "Updated $ENV_DIR/terraform.tfvars"
    fi
    
    # Update backend.tf with environment-specific prefix
    if [ -f "$ENV_DIR/backend.tf" ]; then
        sed -i.bak "s|prefix = \"dev/terraform/state\"|prefix = \"$ENVIRONMENT/terraform/state\"|" "$ENV_DIR/backend.tf"
        print_success "Updated backend configuration for $ENVIRONMENT"
    fi
    
    # Update complete-setup.sh if it exists
    if [ -f "scripts/complete-setup.sh" ]; then
        sed -i.bak "s/PROJECT_ID=\".*\"/PROJECT_ID=\"$PROJECT_ID\"/" scripts/complete-setup.sh
        sed -i.bak "s/REGION=\".*\"/REGION=\"$REGION\"/" scripts/complete-setup.sh
        sed -i.bak "s/CLUSTER_NAME=\".*\"/CLUSTER_NAME=\"$CLUSTER_NAME\"/" scripts/complete-setup.sh
        sed -i.bak "s/GITHUB_USERNAME=\".*\"/GITHUB_USERNAME=\"$GITHUB_USERNAME\"/" scripts/complete-setup.sh
        print_success "Updated scripts/complete-setup.sh"
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
        echo "  2. Run terraform init and terraform apply"
        echo "  3. Or run the complete-setup.sh script"
    fi
}

# Function to show next steps
show_next_steps() {
    print_success "Configuration completed successfully!"
    echo
    echo "Next Steps:"
    echo "==========="
    echo "1. Navigate to your environment directory:"
    echo "   cd environments/non-prod/$ENVIRONMENT"
    echo "   # or cd environments/prod/$ENVIRONMENT for production"
    echo
    echo "2. Run the complete setup script:"
    echo "   ../../scripts/complete-setup.sh"
    echo
    echo "3. Or manually bootstrap FluxCD:"
    echo "   cd environments/non-prod/$ENVIRONMENT"
    echo "   cp flux-bootstrap.tf.example flux-bootstrap.tf"
    echo "   terraform init"
    echo "   terraform apply"
    echo
    echo "4. Deploy your applications via GitOps"
    echo
    echo "Your configuration is now ready for project: $PROJECT_ID"
    echo "Cluster: $CLUSTER_NAME in region: $REGION"
    echo "Environment: $ENVIRONMENT"
    echo
    echo "Quick test command:"
    echo "terraform -chdir=environments/non-prod/$ENVIRONMENT plan"
}

# Main execution
main() {
    # Initialize variables
    PROJECT_ID=""
    REGION=""
    CLUSTER_NAME=""
    GITHUB_USERNAME=""
    ENVIRONMENT="dev"
    FORCE_OVERWRITE=false
    
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
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Create environment structure
    create_environment_structure
    
    # Update configuration files
    update_config_files
    
    # Validate cluster access
    validate_cluster_access
    
    # Check FluxCD status
    check_fluxcd_status
    
    # Show next steps
    show_next_steps
}

# Run main function
main "$@" 