#!/bin/bash

# GitHub Repository Setup Script for GitOps Demo
# This script automates the creation of GitHub repositories needed for the GitOps demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_USERNAME="paraskanwarit"
GITHUB_TOKEN=""
REPO_NAMES=("sample-app-helm-chart" "flux-app-delivery")

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed"
        exit 1
    fi
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        print_error "git is required but not installed"
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Function to get GitHub token
get_github_token() {
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
    
    print_success "GitHub token validated"
}

# Function to create GitHub repository
create_github_repo() {
    local repo_name=$1
    local description=$2
    
    print_status "Creating repository: $repo_name"
    
    # Check if repository already exists
    if curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_USERNAME/$repo_name" | jq -e '.id' > /dev/null 2>&1; then
        print_warning "Repository $repo_name already exists"
        return 0
    fi
    
    # Create repository
    response=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/user/repos \
        -d "{
            \"name\": \"$repo_name\",
            \"description\": \"$description\",
            \"private\": false,
            \"auto_init\": true,
            \"gitignore_template\": \"Node\"
        }")
    
    if echo "$response" | jq -e '.id' > /dev/null; then
        print_success "Repository $repo_name created successfully"
        echo "$response" | jq -r '.html_url'
    else
        print_error "Failed to create repository $repo_name"
        echo "$response" | jq -r '.message'
        exit 1
    fi
}

# Function to push local repository to GitHub
push_to_github() {
    local repo_name=$1
    local local_path=$2
    
    print_status "Pushing $local_path to GitHub repository: $repo_name"
    
    if [ ! -d "$local_path" ]; then
        print_error "Local directory $local_path does not exist"
        return 1
    fi
    
    cd "$local_path"
    
    # Initialize git if not already initialized
    if [ ! -d ".git" ]; then
        git init
        git add .
        git commit -m "Initial commit"
    fi
    
    # Add GitHub remote
    git remote add origin "https://github.com/$GITHUB_USERNAME/$repo_name.git" 2>/dev/null || \
    git remote set-url origin "https://github.com/$GITHUB_USERNAME/$repo_name.git"
    
    # Push to GitHub
    if git push -u origin main; then
        print_success "Successfully pushed $local_path to GitHub"
    else
        print_warning "Failed to push to GitHub. You may need to manually push the repository."
        print_status "Repository URL: https://github.com/$GITHUB_USERNAME/$repo_name"
    fi
    
    cd - > /dev/null
}

# Function to setup sample-app-helm-chart repository
setup_helm_chart_repo() {
    local repo_name="sample-app-helm-chart"
    local description="Sample NGINX application Helm chart for GitOps demo"
    
    print_status "Setting up Helm chart repository..."
    
    # Create GitHub repository
    create_github_repo "$repo_name" "$description"
    
    # Push local repository
    if [ -d "../sample-app-helm-chart" ]; then
        push_to_github "$repo_name" "../sample-app-helm-chart"
    else
        print_warning "Local sample-app-helm-chart directory not found. Please create it manually."
    fi
}

# Function to setup flux-app-delivery repository
setup_delivery_repo() {
    local repo_name="flux-app-delivery"
    local description="FluxCD application delivery manifests for GitOps demo"
    
    print_status "Setting up FluxCD delivery repository..."
    
    # Create GitHub repository
    create_github_repo "$repo_name" "$description"
    
    # Push local repository
    if [ -d "../flux-app-delivery" ]; then
        push_to_github "$repo_name" "../flux-app-delivery"
    else
        print_warning "Local flux-app-delivery directory not found. Please create it manually."
    fi
}

# Function to display setup summary
display_summary() {
    print_success "GitHub repository setup completed!"
    echo
    echo "Created repositories:"
    echo "  - https://github.com/$GITHUB_USERNAME/sample-app-helm-chart"
    echo "  - https://github.com/$GITHUB_USERNAME/flux-app-delivery"
    echo
    echo "Next steps:"
    echo "  1. Verify repositories are accessible"
    echo "  2. Continue with FluxCD bootstrap"
    echo "  3. Deploy application via GitOps"
}

# Main execution
main() {
    echo "🚀 GitHub Repository Setup for GitOps Demo"
    echo "=========================================="
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Get GitHub token
    get_github_token
    
    # Setup repositories
    setup_helm_chart_repo
    setup_delivery_repo
    
    # Display summary
    display_summary
}

# Run main function
main "$@" 