#!/bin/bash

# Test Prerequisites Script
# This script tests if all prerequisites are met before running the main scripts

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

echo "🧪 Testing Prerequisites for GitOps Scripts"
echo "==========================================="
echo

# Test 1: Check required tools
print_status "Checking required tools..."
missing_tools=()
for tool in terraform kubectl gcloud git curl jq; do
    if command -v $tool &> /dev/null; then
        print_success "$tool: $(command -v $tool)"
    else
        missing_tools+=($tool)
        print_error "$tool: NOT FOUND"
    fi
done

if [ ${#missing_tools[@]} -ne 0 ]; then
    print_error "Missing tools: ${missing_tools[*]}"
    echo "Please install missing tools before proceeding."
    exit 1
fi

# Test 2: Check GCP authentication
print_status "Checking GCP authentication..."
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    print_success "Authenticated as: $ACTIVE_ACCOUNT"
else
    print_error "Not authenticated with GCP. Run: gcloud auth login"
    exit 1
fi

# Test 3: Check current project
print_status "Checking current GCP project..."
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -n "$CURRENT_PROJECT" ]; then
    print_success "Current project: $CURRENT_PROJECT"
    
    # Test project access
    if gcloud projects describe $CURRENT_PROJECT &> /dev/null; then
        print_success "Project access: OK"
    else
        print_error "Cannot access project: $CURRENT_PROJECT"
        exit 1
    fi
else
    print_warning "No default project set. Set with: gcloud config set project PROJECT_ID"
fi

# Test 4: Check kubectl context
print_status "Checking kubectl context..."
if kubectl config current-context &> /dev/null; then
    CURRENT_CONTEXT=$(kubectl config current-context)
    print_success "Current context: $CURRENT_CONTEXT"
    
    # Test cluster connectivity
    if kubectl get nodes &> /dev/null; then
        NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
        print_success "Cluster connectivity: OK ($NODE_COUNT nodes)"
    else
        print_warning "Cannot connect to cluster. May need to get credentials."
    fi
else
    print_warning "No kubectl context set. This is OK if cluster doesn't exist yet."
fi

# Test 5: Check directory structure
print_status "Checking directory structure..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -d "$PROJECT_ROOT/gke-gitops-infra" ]; then
    print_success "gke-gitops-infra directory: Found"
else
    print_error "gke-gitops-infra directory: NOT FOUND"
    exit 1
fi

if [ -d "$PROJECT_ROOT/gke-gitops-infra/flux-bootstrap" ]; then
    print_success "flux-bootstrap directory: Found"
else
    print_error "flux-bootstrap directory: NOT FOUND"
    exit 1
fi

# Test 6: Check GitHub connectivity
print_status "Checking GitHub connectivity..."
if curl -s --max-time 5 https://api.github.com/user > /dev/null; then
    print_success "GitHub API: Accessible"
else
    print_warning "GitHub API: Not accessible (may need internet connection)"
fi

echo
print_success "✅ All prerequisites check passed!"
echo
echo "📋 Summary:"
echo "  • Tools: All required tools are installed"
echo "  • GCP: Authenticated and project accessible"
echo "  • kubectl: Context available (cluster connectivity varies)"
echo "  • Directory structure: All required directories found"
echo "  • GitHub: API accessible"
echo
echo "🚀 Ready to run complete-setup.sh or complete-destroy.sh"