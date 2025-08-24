#!/usr/bin/env bash

# Script to update the separate flux-app-delivery repository with latest changes
# This ensures the GitOps repository has the comprehensive README and diagrams

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

GITHUB_USERNAME="${GITHUB_USERNAME:-paraskanwarit}"
TEMP_DIR="/tmp/flux-app-delivery-update"

echo "📦 Updating flux-app-delivery repository with latest documentation"
echo "=================================================================="
echo

# Clean up any existing temp directory
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# Clone the separate repository
print_status "Cloning flux-app-delivery repository..."
git clone https://github.com/$GITHUB_USERNAME/flux-app-delivery.git "$TEMP_DIR"

# Copy updated files from our local development
print_status "Copying updated documentation and diagrams..."

# Check if we have the comprehensive README from our development
if [ -f "flux-app-delivery/README.md" ]; then
    print_status "Copying comprehensive README..."
    cp "flux-app-delivery/README.md" "$TEMP_DIR/README.md"
else
    print_warning "Local comprehensive README not found, skipping..."
fi

# Copy diagrams if they exist
if [ -f "flux-app-delivery/diagram-delivery.md" ]; then
    print_status "Copying delivery diagram..."
    cp "flux-app-delivery/diagram-delivery.md" "$TEMP_DIR/diagram-delivery.md"
fi

if [ -f "flux-app-delivery/diagram-end-to-end.md" ]; then
    print_status "Copying end-to-end diagram..."
    cp "flux-app-delivery/diagram-end-to-end.md" "$TEMP_DIR/diagram-end-to-end.md"
fi

if [ -f "flux-app-delivery/diagram-change-workflow.md" ]; then
    print_status "Copying change workflow diagram..."
    cp "flux-app-delivery/diagram-change-workflow.md" "$TEMP_DIR/diagram-change-workflow.md"
fi

# Navigate to the repository and commit changes
cd "$TEMP_DIR"

# Check if there are any changes
if git diff --quiet && git diff --cached --quiet; then
    print_success "Repository is already up to date!"
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    exit 0
fi

# Add and commit changes
print_status "Committing updates..."
git add .
git commit -m "Update documentation and diagrams for production-grade GitOps

✅ Updates:
- Comprehensive README with detailed object explanations
- Simplified flow diagrams for better demo presentation
- Production-grade architecture documentation
- Clear separation of concerns explanation

✅ Features:
- Detailed Kubernetes object definitions and purposes
- GitOps workflow examples
- Troubleshooting and monitoring guidance
- Demo flow instructions

This repository now serves as a complete reference for GitOps
configuration and deployment patterns."

# Push changes
print_status "Pushing updates to GitHub..."
git push origin main

print_success "flux-app-delivery repository updated successfully!"

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo
print_status "✅ Repository update completed!"
echo "🌐 View updated repository: https://github.com/$GITHUB_USERNAME/flux-app-delivery"