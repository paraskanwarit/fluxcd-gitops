#!/usr/bin/env bash
# Ensure we’re running under bash even if invoked as `sh script`
if [ -z "${BASH_VERSION:-}" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash "$0" "$@"
  else
    echo "This script requires bash. Run: bash $0" >&2
    exit 1
  fi
fi

# Complete GitOps Destroy Script (scoped, non-destructive)
# - Only removes objects created by the setup script
# - Uninstalls Flux via Terraform in gke-gitops-infra/flux-bootstrap
# - Preserves kubectl context by default (opt-in to delete)
# - Handles GKE NEG finalizers in app namespace to avoid stuck deletions

set -Eeuo pipefail

# ---------------------------------------
# Colors & printing
# ---------------------------------------
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; PURPLE=$'\033[0;35m'; NC=$'\033[0m'
print_status()  { printf "%b[INFO]%b %s\n"    "$BLUE"   "$NC" "$*"; }
print_success() { printf "%b[SUCCESS]%b %s\n" "$GREEN"  "$NC" "$*"; }
print_warning() { printf "%b[WARNING]%b %s\n" "$YELLOW" "$NC" "$*"; }
print_error()   { printf "%b[ERROR]%b %s\n"   "$RED"    "$NC" "$*"; }
print_step()    { printf "%b[STEP]%b %s\n"    "$PURPLE" "$NC" "$*"; }

# ---------------------------------------
# Config (aligned with setup script)
# ---------------------------------------
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || echo 'extreme-gecko-466211-t1')}"
REGION="${REGION:-us-central1}"
CLUSTER_NAME="${CLUSTER_NAME:-dev-gke-autopilot}"
GITHUB_USERNAME="${GITHUB_USERNAME:-paraskanwarit}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# Exact GitOps objects created by setup
FLUX_NS="flux-system"
DELIVERY_KUSTOMIZATION="${DELIVERY_KUSTOMIZATION:-flux-app-delivery}"
DELIVERY_GITREPO="${DELIVERY_GITREPO:-flux-app-delivery}"
APP_NAMESPACE="${APP_NAMESPACE:-sample-app}"
APP_HELMRELEASE="${APP_HELMRELEASE:-sample-app2}"

# Flux controller deployments (created by TF module)
FLUX_DEPLOYMENTS=("source-controller" "helm-controller" "kustomize-controller")

# Options
PRESERVE_KUBECTL_CONTEXT="${PRESERVE_KUBECTL_CONTEXT:-true}"
FORCE_DELETE_APP_NAMESPACE_FINALIZERS="${FORCE_DELETE_APP_NAMESPACE_FINALIZERS:-false}"

# Resolve paths relative to this file
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUX_TF_DIR="${FLUX_TF_DIR:-$REPO_ROOT/gke-gitops-infra/flux-bootstrap}"
SCRIPTS_DIR="$REPO_ROOT/scripts"

# Hard safety: don’t destroy infra/env modules
if [[ "$FLUX_TF_DIR" == *"/environment/"* ]]; then
  print_error "FLUX_TF_DIR points at an environment/cluster module. This script will not destroy clusters."
  print_error "Expected Flux bootstrap module: gke-gitops-infra/flux-bootstrap"
  exit 1
fi

# ---------------------------------------
# Helpers
# ---------------------------------------
ok()          { command -v "$1" >/dev/null 2>&1; }
exists_ns()   { kubectl get ns "$1" >/dev/null 2>&1; }
exists_res()  { kubectl get "$@" >/dev/null 2>&1; }

wait_for_ns_gone() {
  local ns="$1" timeout="${2:-180}" waited=0
  while exists_ns "$ns"; do
    sleep 5
    waited=$((waited+5))
    (( waited >= timeout )) && return 1
  done
  return 0
}

ns_diag() {
  local ns="$1"
  print_status "Namespace $ns diagnostics:"
  kubectl get ns "$ns" -o 'custom-columns=NAME:.metadata.name,PHASE:.status.phase,FINALIZERS:.spec.finalizers' || true
  kubectl get events -n "$ns" --sort-by=.lastTimestamp | tail -n 10 || true
}

# Scoped to app namespace: clear GKE Service NEG finalizers that block deletion
clear_gke_neg_finalizers_in_ns() {
  local ns="$1"
  local snegs
  snegs="$(kubectl -n "$ns" get servicenetworkendpointgroups.networking.gke.io -o name 2>/dev/null || true)"
  if [[ -n "$snegs" ]]; then
    print_status "Detected SNEG resources in $ns; removing networking.gke.io/neg-finalizer"
    local s
    for s in $snegs; do
      print_status "Patching $s"
      kubectl -n "$ns" patch "$s" --type=merge -p '{"metadata":{"finalizers":[]}}' || true
    done
  else
    print_status "No SNEG resources found in $ns."
  fi
}

# ---------------------------------------
# Traps
# ---------------------------------------
_script_failed=true
on_err() {
  local ec=$?
  print_error "Command failed (exit $ec): '$BASH_COMMAND' at ${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
  _script_failed=true
  exit $ec
}
on_exit() {
  if [[ "$_script_failed" == "true" ]]; then
    print_warning "Script exited early or failed; some resources may still exist."
  end_if_dummy=
  fi
}
trap on_err ERR
trap on_exit EXIT

# ---------------------------------------
# Prereqs and context
# ---------------------------------------
check_prerequisites() {
  print_step "Checking prerequisites..."
  local missing=()
  local t
  for t in terraform kubectl gcloud curl jq; do ok "$t" || missing+=("$t"); done
  if (( ${#missing[@]} )); then
    print_error "Missing required tools: ${missing[*]}"
    exit 1
  fi
  if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_error "GCP authentication required. Run: gcloud auth login"
    exit 1
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
  printf "\nExecution Paths\n==================\n"
  printf " Script dir         : %s\n" "$SCRIPT_DIR"
  printf " Repo root          : %s\n" "$REPO_ROOT"
  printf " Terraform (Flux)   : %s\n" "$FLUX_TF_DIR"
  printf " Expected scripts   : %s\n\n" "$SCRIPTS_DIR"
  [[ -d "$FLUX_TF_DIR" ]] || { print_error "Flux Terraform dir not found: $FLUX_TF_DIR"; exit 1; }
}

# ---------------------------------------
# App removal (Flux-first, scoped)
# ---------------------------------------
remove_gitops_applications() {
  print_step "Removing GitOps-managed application (scoped)"

  if ! kubectl cluster-info >/dev/null 2>&1; then
    print_warning "Cluster not accessible; skipping app cleanup."
    return 0
  fi

  # 1) Delete the Kustomization (prunes its children only)
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

    if wait_for_ns_gone "$APP_NAMESPACE" 240; then
      print_success "Application namespace removed."
    else
      print_warning "Namespace $APP_NAMESPACE still terminating; checking for GKE SNEGs with neg-finalizer..."
      ns_diag "$APP_NAMESPACE"
      clear_gke_neg_finalizers_in_ns "$APP_NAMESPACE"

      print_status "Retrying namespace deletion for $APP_NAMESPACE"
      kubectl delete ns "$APP_NAMESPACE" --ignore-not-found=true || true
      if wait_for_ns_gone "$APP_NAMESPACE" 180; then
        print_success "Application namespace removed after clearing SNEG finalizers."
      else
        if [[ "$FORCE_DELETE_APP_NAMESPACE_FINALIZERS" == "true" ]]; then
          print_warning "FORCE_DELETE_APP_NAMESPACE_FINALIZERS=true -> removing namespace finalizers (last resort)"
          kubectl get ns "$APP_NAMESPACE" -o json \
            | jq 'del(.spec.finalizers)' \
            | kubectl replace --raw "/api/v1/namespaces/$APP_NAMESPACE/finalize" -f - || true
          if wait_for_ns_gone "$APP_NAMESPACE" 120; then
            print_success "Application namespace forcibly removed."
          else
            print_warning "Namespace $APP_NAMESPACE still terminating after force; manual investigation required."
          fi
        else
          print_warning "Namespace $APP_NAMESPACE still terminating; investigate remaining finalizers:"
          print_status "kubectl get ns $APP_NAMESPACE -o json | jq '.spec.finalizers'"
        fi
      fi
    fi
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

  # Minimal manual check: if Flux namespace still exists, delete only known controller deployments
  if exists_ns "$FLUX_NS"; then
    print_status "Flux namespace still present; removing only known controller deployments"
    local d
    for d in "${FLUX_DEPLOYMENTS[@]}"; do
      if exists_res deploy "$d" -n "$FLUX_NS"; then
        kubectl -n "$FLUX_NS" delete deploy "$d" --ignore-not-found=true
        kubectl -n "$FLUX_NS" wait --for=delete "deploy/$d" --timeout=120s || true
      fi
    done

    # If namespace is empty, delete it; otherwise leave it
    local remains
    remains="$(kubectl -n "$FLUX_NS" get all,secret,role,rolebinding 2>/dev/null | sed -n '2p' || true)"
    if [[ -z "$remains" ]]; then
      print_status "Flux namespace appears empty; deleting namespace $FLUX_NS"
      kubectl delete ns "$FLUX_NS" --ignore-not-found=true || true
      wait_for_ns_gone "$FLUX_NS" 180 || print_warning "Namespace $FLUX_NS still terminating; clear finalizers manually only if safe."
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
      read -r -s -p "Enter your GitHub Personal Access Token: " GITHUB_TOKEN; printf "\n"
    fi
    if ! curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | jq -e '.login' >/dev/null; then
      print_error "Invalid GitHub token. Skipping repo cleanup."
      return 0
    fi
    local repo
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
    printf "Repos remain:\n  - https://github.com/%s/sample-app-helm-chart\n  - https://github.com/%s/flux-app-delivery\n" "$GITHUB_USERNAME" "$GITHUB_USERNAME"
  fi
}

# ---------------------------------------
# Kubectl context cleanup (opt-in)
# ---------------------------------------
cleanup_kubectl_context() {
  print_step "Cleaning up kubectl context"
  if [[ "${PRESERVE_KUBECTL_CONTEXT}" == "true" ]]; then
    print_status "PRESERVE_KUBECTL_CONTEXT=true -> Skipping kubectl context cleanup."
    return 0
  fi
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
display_summary() {
  print_success "GitOps Demo Destruction Completed!"
  printf "\nCleanup Summary:\n"
  printf "  Removed: Kustomization/%s, GitRepository/%s\n" "$DELIVERY_KUSTOMIZATION" "$DELIVERY_GITREPO"
  printf "  Removed: HelmRelease/%s, Namespace/%s (if present)\n" "$APP_HELMRELEASE" "$APP_NAMESPACE"
  printf "  Removed: Flux via Terraform module (dir: %s); no CRDs touched\n" "$FLUX_TF_DIR"
  printf "\nRemaining (if you skipped repo deletion):\n"
  printf "  • https://github.com/%s/sample-app-helm-chart\n" "$GITHUB_USERNAME"
  printf "  • https://github.com/%s/flux-app-delivery\n" "$GITHUB_USERNAME"
  printf "\nVerify in GCP Console:\n  • https://console.cloud.google.com/kubernetes/list?project=%s\n" "$PROJECT_ID"
}

# ---------------------------------------
# Main
# ---------------------------------------
main() {
  printf "\nComplete GitOps Demo Destruction (scoped)\n===========================================\n"
  print_paths
  printf "\n"
  read -r -p "Proceed with cleanup in project $PROJECT_ID, region $REGION? (y/N) " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { printf "Destruction cancelled.\n"; exit 0; }

  detect_cluster_from_context
  print_status "Using cluster: $CLUSTER_NAME (project: $PROJECT_ID, region: $REGION)"

  check_prerequisites
  remove_gitops_applications
  destroy_fluxcd
  cleanup_github_repos
  cleanup_kubectl_context

  # Success: disable ERR trap to prevent spurious final messages
  _script_failed=false
  trap - ERR
  display_summary
}

main "$@"
