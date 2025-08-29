#!/usr/bin/env bash
#
# Complete GitOps Destroy Script (scoped, non-destructive)
# - Only removes objects created by your setup script
# - No CRD deletions, no cluster-scoped deletions, no wildcard --all
# - Uses Terraform in gke-gitops-infra/flux-bootstrap (same path as setup)
#

set -Eeuo pipefail

# ---------------------------------------
# Colors & printing
# ---------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'
print_status()  { echo -e "${BLUE}[INFO]${NC} $*"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
print_step()    { echo -e "${PURPLE}[STEP]${NC} $*"; }

# ---------------------------------------
# Config (aligned with setup script)
# ---------------------------------------
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || echo 'extreme-gecko-466211-t1')}"
REGION="${REGION:-us-central1}"
CLUSTER_NAME="${CLUSTER_NAME:-dev-gke-autopilot}"
GITHUB_USERNAME="${GITHUB_USERNAME:-paraskanwarit}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# Exact objects created by setup
FLUX_NS="flux-system"
DELIVERY_KUSTOMIZATION="${DELIVERY_KUSTOMIZATION:-flux-app-delivery}"
DELIVERY_GITREPO="${DELIVERY_GITREPO:-flux-app-delivery}"

APP_NAMESPACE="${APP_NAMESPACE:-sample-app}"
APP_HELMRELEASE="${APP_HELMRELEASE:-sample-app2}"

# Flux controller deployments created by the bootstrap TF module
FLUX_DEPLOYMENTS=("source-controller" "helm-controller" "kustomize-controller")

# Resolve paths from this files location
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUX_TF_DIR="${FLUX_TF_DIR:-$REPO_ROOT/gke-gitops-infra/flux-bootstrap}"
SCRIPTS_DIR="$REPO_ROOT/scripts"

ok() { command -v "$1" >/dev/null 2>&1; }
exists_ns() { kubectl get ns "$1" >/dev/null 2>&1; }
exists_res() { kubectl get "$@" >/dev/null 2>&1; }

# ---------------------------------------
# Prereqs
# ---------------------------------------
check_prerequisites() {
  print_step "Checking prerequisites..."
  local missing=()
  for t in terraform kubectl gcloud curl jq; do ok "$t" || missing+=("$t"); done
  if (( ${#missing[@]} )); then
    print_error "Missing required tools: ${missing[*]}"; exit 1
  fi
  if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_error "GCP authentication required. Run: gcloud auth login"; exit 1
  fi
  print_success "All prerequisites are met"
}

detect_cluster_from_context() {
  if kubectl config current-context >/dev/null 2>&1; then
    local ctx; ctx="$(kubectl config current-context || true)"
    if [[ "$ctx" == gke_* ]]; then
      local detected; detected="$(cut -d'_' -f4 <<<"$ctx")"
      [[ -n "${detected:-}" ]] && CLUSTER_NAME="$detected"
    fi
  fi
}

print_paths() {
  echo
  echo " Execution Paths"
  echo "=================="
  echo " Script dir         : $SCRIPT_DIR"
  echo " Repo root          : $REPO_ROOT"
  echo " Terraform (Flux)   : $FLUX_TF_DIR"
  echo " Expected scripts   : $SCRIPTS_DIR"
  echo
  [[ -d "$FLUX_TF_DIR" ]] || { print_error "Flux Terraform dir not found: $FLUX_TF_DIR"; exit 1; }
}

# ---------------------------------------
# App removal (Flux-first, scoped)
# ---------------------------------------
remove_gitops_applications() {
  print_step "Removing GitOps-managed application (scoped)"

  if ! kubectl cluster-info >/dev/null 2>&1; then
    print_warning "Cluster not accessible; skipping app cleanup."; return 0
  fi

  # 1) Delete the Kustomization (triggers prune of *its* children only)
  if exists_res kustomization "$DELIVERY_KUSTOMIZATION" -n "$FLUX_NS"; then
    print_status "Deleting Kustomization $DELIVERY_KUSTOMIZATION in $FLUX_NS"
    kubectl -n "$FLUX_NS" delete kustomization "$DELIVERY_KUSTOMIZATION" --ignore-not-found=true
    kubectl -n "$FLUX_NS" wait --for=delete "kustomization/$DELIVERY_KUSTOMIZATION" --timeout=180s || true
  else
    print_status "Kustomization $DELIVERY_KUSTOMIZATION not found."
  fi

  # 2) Delete the GitRepository used by that Kustomization
  if exists_res gitrepository "$DELIVERY_GITREPO" -n "$FLUX_NS"; then
    print_status "Deleting GitRepository $DELIVERY_GITREPO in $FLUX_NS"
    kubectl -n "$FLUX_NS" delete gitrepository "$DELIVERY_GITREPO" --ignore-not-found=true
    kubectl -n "$FLUX_NS" wait --for=delete "gitrepository/$DELIVERY_GITREPO" --timeout=120s || true
  else
    print_status "GitRepository $DELIVERY_GITREPO not found."
  fi

  # 3) If HelmRelease still exists (e.g., Kustomization absent), remove just that one
  if kubectl api-resources --api-group=helm.toolkit.fluxcd.io >/dev/null 2>&1; then
    if exists_res helmrelease "$APP_HELMRELEASE" -n "$APP_NAMESPACE"; then
      print_status "Deleting HelmRelease $APP_HELMRELEASE in $APP_NAMESPACE"
      kubectl -n "$APP_NAMESPACE" delete helmrelease "$APP_HELMRELEASE" --ignore-not-found=true
      kubectl -n "$APP_NAMESPACE" wait --for=delete "helmrelease/$APP_HELMRELEASE" --timeout=180s || true
    fi
  fi

  # 4) Remove the app namespace only if it still exists (no wildcards)
  if exists_ns "$APP_NAMESPACE"; then
    print_status "Deleting application namespace $APP_NAMESPACE"
    kubectl delete ns "$APP_NAMESPACE" --ignore-not-found=true
    # Gentle wait with a short timeout; do NOT mass-patch random resources
    for _ in {1..60}; do
      exists_ns "$APP_NAMESPACE" || { print_success "Application namespace removed."; return 0; }
      sleep 2
    done
    print_warning "Namespace $APP_NAMESPACE still terminating; you may clear finalizers manually *if safe*."
  else
    print_status "Application namespace $APP_NAMESPACE not found."
  fi
}

# ---------------------------------------
# Terraform destroy of Flux (scoped)
# ---------------------------------------
destroy_fluxcd() {
  print_step "Destroying FluxCD via Terraform (same module as setup)"

  # Gather cluster details like in setup
  export CLUSTER_ENDPOINT="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || true)"
  export CLUSTER_CA_CERT="$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' 2>/dev/null || true)"
  export GKE_TOKEN="$(gcloud auth print-access-token 2>/dev/null || true)"

  pushd "$FLUX_TF_DIR" >/dev/null
    print_status "Terraform dir: $(pwd)"
    terraform init -input=false
    terraform destroy -auto-approve \
      -var="cluster_endpoint=$CLUSTER_ENDPOINT" \
      -var="cluster_ca_certificate=$CLUSTER_CA_CERT" \
      -var="gke_token=$GKE_TOKEN" || print_warning "Terraform destroy returned non-zero; minimal manual checks will follow."
  popd >/dev/null

  # Minimal manual check: if Flux namespace still exists, delete only the known controller deployments
  if exists_ns "$FLUX_NS"; then
    print_status "Flux namespace still present; removing only known controller deployments"
    for d in "${FLUX_DEPLOYMENTS[@]}"; do
      if exists_res deploy "$d" -n "$FLUX_NS"; then
        kubectl -n "$FLUX_NS" delete deploy "$d" --ignore-not-found=true
        kubectl -n "$FLUX_NS" wait --for=delete "deploy/$d" --timeout=120s || true
      fi
    done

    # If namespace becomes empty, delete it; otherwise leave it (no sweeping deletes).
    if [[ -z "$(kubectl -n "$FLUX_NS" get all,secret,role,rolebinding 2>/dev/null | sed -n '2p')" ]]; then
      print_status "Flux namespace appears empty; deleting namespace $FLUX_NS"
      kubectl delete ns "$FLUX_NS" --ignore-not-found=true || true
    else
      print_warning "Leaving namespace $FLUX_NS intact because non-target resources remain."
    fi
  fi

  print_success "FluxCD uninstall step completed."
}

# ---------------------------------------
# GitHub cleanup (optional)
# ---------------------------------------
cleanup_github_repos() {
  print_step "GitHub repository cleanup (optional)"
  read -r -p "Delete the GitHub repositories created for this demo? (y/N) " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
      print_warning "GitHub token not provided"
      read -r -s -p "Enter your GitHub Personal Access Token: " GITHUB_TOKEN; echo
    fi
    if ! curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | jq -e '.login' >/dev/null; then
      print_error "Invalid GitHub token. Skipping repo cleanup."; return 0
    fi
    for repo in "sample-app-helm-chart" "flux-app-delivery"; do
      print_status "Deleting repo: $repo"
      curl -s -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$GITHUB_USERNAME/$repo" >/dev/null || true
    done
    print_success "Requested GitHub repo deletion."
  else
    print_status "Skipping GitHub repository cleanup"
    echo "Repos remain:"
    echo "  - https://github.com/$GITHUB_USERNAME/sample-app-helm-chart"
    echo "  - https://github.com/$GITHUB_USERNAME/flux-app-delivery"
  fi
}

# ---------------------------------------
# Kubectl context cleanup (optional nicety)
# ---------------------------------------
cleanup_kubectl_context() {
  print_step "Cleaning up kubectl context"
  local ctx="gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}"
  if kubectl config get-contexts -o name | grep -qx "$ctx"; then
    print_status "Removing kubectl context/cluster/user: $ctx"
    kubectl config delete-context "$ctx" || print_warning "Failed to delete context"
    kubectl config delete-cluster "$ctx" || print_warning "Failed to delete cluster config"
    kubectl config delete-user "$ctx" || print_warning "Failed to delete user config"
    print_success "kubectl context cleaned up"
  else
    print_status "kubectl context $ctx not found; skipping"
  fi
}

# ---------------------------------------
# Summary
# ---------------------------------------
_script_failed=false
trap - ERR

display_summary() {
  print_success " GitOps Demo Destruction Completed!"
  echo
  echo " Cleanup Summary:"
  echo "   Removed: Kustomization/$DELIVERY_KUSTOMIZATION, GitRepository/$DELIVERY_GITREPO"
  echo "   Removed: HelmRelease/$APP_HELMRELEASE, Namespace/$APP_NAMESPACE (if present)"
  echo "   Removed: Flux controllers via Terraform (dir: $FLUX_TF_DIR); no CRDs touched"
  echo
  echo " Remaining (if you skipped repo deletion):"
  echo "   https://github.com/$GITHUB_USERNAME/sample-app-helm-chart"
  echo "   https://github.com/$GITHUB_USERNAME/flux-app-delivery"
  echo
  echo " Verify in GCP Console:"
  echo "   https://console.cloud.google.com/kubernetes/list?project=$PROJECT_ID"
}

# ---------------------------------------
# Traps
# ---------------------------------------
_script_failed=true
on_exit() { [[ "$_script_failed" == "true" ]] && print_warning "Script exited early or failed; some resources may still exist."; }
trap on_exit EXIT
trap 'print_error "Error on line $LINENO"; exit 1' ERR

# ---------------------------------------
# Main
# ---------------------------------------
main() {
  echo " Complete GitOps Demo Destruction (scoped)"
  echo "==========================================="
  print_paths
  echo
  read -r -p "Proceed with cleanup in project $PROJECT_ID, region $REGION? (y/N) " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Destruction cancelled."; exit 0; }

  detect_cluster_from_context
  print_status "Using cluster: $CLUSTER_NAME (project: $PROJECT_ID, region: $REGION)"

  check_prerequisites
  remove_gitops_applications
  destroy_fluxcd
  cleanup_github_repos
  cleanup_kubectl_context

  _script_failed=false
  display_summary
}

main "$@"