#!/usr/bin/env bash

# Script to clean up duplicate flux-app-delivery folder
# This removes the local folder since we're using the separate repository approach

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

echo "🧹 Cleaning up duplicate flux-app-delivery folder"
echo "=================================================="
echo

print_status "Current repository structure uses SEPARATE repositories approach:"
echo "  ✅ Infrastructure: https://github.com/paraskanwarit/fluxcd-gitops"
echo "  ✅ GitOps Config:  https://github.com/paraskanwarit/flux-app-delivery"
echo "  ✅ Helm Charts:    https://github.com/paraskanwarit/sample-app-helm-chart"
echo

if [ -d "flux-app-delivery" ]; then
    print_warning "Found duplicate flux-app-delivery folder in main repository"
    print_status "This folder is redundant since we use the separate repository approach"
    
    echo
    read -p "Do you want to remove the duplicate folder? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removing duplicate flux-app-delivery folder..."
        rm -rf flux-app-delivery
        print_success "Duplicate folder removed!"
        
        print_status "Updating .gitignore to prevent future confusion..."
        if ! grep -q "flux-app-delivery/" .gitignore 2>/dev/null; then
            echo "# Prevent duplicate flux-app-delivery folder (use separate repo)" >> .gitignore
            echo "flux-app-delivery/" >> .gitignore
            print_success "Added flux-app-delivery/ to .gitignore"
        fi
        
        print_status "Committing cleanup changes..."
        git add .
        git commit -m "Remove duplicate flux-app-delivery folder

- Use separate repository approach for GitOps configuration
- flux-app-delivery is maintained at: https://github.com/paraskanwarit/flux-app-delivery
- Added to .gitignore to prevent future duplication"
        
        print_success "Cleanup completed!"
        echo
        print_status "Repository structure is now clean:"
        echo "  📁 fluxcd-gitops/ (this repo)"
        echo "    ├── gke-gitops-infra/     # Infrastructure code"
        echo "    ├── scripts/              # Setup scripts"
        echo "    └── README.md"
        echo
        echo "  📁 flux-app-delivery/ (separate repo)"
        echo "    ├── helmrelease/          # GitOps manifests"
        echo "    ├── namespaces/"
        echo "    └── README.md"
        echo
        echo "  📁 sample-app-helm-chart/ (separate repo)"
        echo "    └── charts/sample-app/    # Helm chart"
        
    else
        print_warning "Keeping duplicate folder. Consider removing it manually for cleaner structure."
    fi
else
    print_success "No duplicate folder found. Repository structure is already clean!"
fi

echo
print_status "✅ Your GitOps setup follows best practices with separate repositories!"