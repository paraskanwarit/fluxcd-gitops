# Setting Up GitOps with a New Project

This guide shows you how to use this GitOps infrastructure with a different GCP project and GKE cluster.

## Prerequisites

- GCP project with billing enabled
- Existing GKE cluster (Autopilot or Standard)
- GCP authentication configured (`gcloud auth login`)
- Required tools: `gcloud`, `kubectl`, `terraform`

## Quick Setup

### Option 1: Automated Setup (Recommended)

1. **Run the setup script**:
   ```bash
   ./scripts/setup-new-project.sh
   ```

2. **Follow the prompts** to enter:
   - GCP Project ID
   - GKE cluster region
   - GKE cluster name
   - GitHub username

3. **The script will automatically**:
   - Update all configuration files
   - Validate cluster access
   - Check FluxCD status
   - Show next steps

### Option 2: Manual Configuration

1. **Copy the configuration template**:
   ```bash
   cp config-template.tfvars environments/non-prod/dev/terraform.tfvars
   ```

2. **Edit the configuration**:
   ```bash
   # Update these values in environments/non-prod/dev/terraform.tfvars
   project_id = "your-actual-project-id"
   region     = "your-actual-region"
   cluster_name = "your-actual-cluster-name"
   ```

3. **Update the setup script**:
   ```bash
   # Edit scripts/complete-setup.sh and update these variables
   PROJECT_ID="your-actual-project-id"
   REGION="your-actual-region"
   CLUSTER_NAME="your-actual-cluster-name"
   GITHUB_USERNAME="your-github-username"
   ```

## How It Works

### Data Source Approach

The infrastructure uses Terraform data sources to fetch information from your existing cluster:

```hcl
# This automatically gets info from ANY existing GKE cluster
data "google_container_cluster" "existing_cluster" {
  name     = var.cluster_name      # Your cluster name
  location = var.region           # Your cluster region
  project  = var.project_id       # Your project ID
}
```

**No new infrastructure is created** - it only reads existing cluster data.

### What Gets Deployed

1. **FluxCD** (optional): GitOps continuous delivery platform
2. **Applications**: Your Helm charts and applications
3. **GitOps Resources**: GitRepository, HelmRelease, etc.

### What Does NOT Get Created

- ❌ No new GKE cluster
- ❌ No new VPC networks
- ❌ No new compute resources
- ❌ No infrastructure changes

## Verification Steps

1. **Check cluster access**:
   ```bash
   gcloud container clusters get-credentials YOUR_CLUSTER_NAME \
     --region=YOUR_REGION --project=YOUR_PROJECT_ID
   kubectl get nodes
   ```

2. **Run the complete setup**:
   ```bash
   ./scripts/complete-setup.sh
   ```

3. **Verify FluxCD installation**:
   ```bash
   kubectl get deployment -n flux-system
   ```

## Example: Different Project Setup

### Current Project
```bash
PROJECT_ID="extreme-gecko-466211-t1"
REGION="us-central1"
CLUSTER_NAME="dev-gke-autopilot"
```

### New Project
```bash
PROJECT_ID="my-new-project-123"
REGION="us-west1"
CLUSTER_NAME="production-cluster"
```

### What Changes
- **Data source automatically fetches** new cluster information
- **Same Terraform code** works with different clusters
- **Same FluxCD setup** process
- **Same application deployment** workflow

## Troubleshooting

### Common Issues

1. **Cluster not found**:
   - Verify cluster name, region, and project ID
   - Check if you have access to the project
   - Ensure the cluster is running

2. **Authentication failed**:
   - Run `gcloud auth login`
   - Verify project access: `gcloud projects list`

3. **Port conflicts**:
   - Change port in scripts if 8080 is in use
   - Kill existing port-forward processes

### Debug Commands

```bash
# Check cluster status
gcloud container clusters describe CLUSTER_NAME --region=REGION --project=PROJECT_ID

# Test cluster connectivity
kubectl cluster-info

# Check FluxCD status
kubectl get deployment -n flux-system

# View cluster resources
kubectl get nodes
kubectl get pods -A
```

## Benefits of This Approach

1. **Reusable**: Same code works with any GKE cluster
2. **Safe**: No risk of modifying existing infrastructure
3. **Flexible**: Works with Autopilot, Standard, or custom clusters
4. **Scalable**: Easy to replicate across multiple projects
5. **GitOps Ready**: Immediate FluxCD and application deployment capability

## Next Steps

After setup:
1. **Customize applications**: Update Helm charts for your needs
2. **Configure GitOps**: Set up your application repositories
3. **Deploy applications**: Use the GitOps pipeline for deployments
4. **Monitor**: Set up monitoring and alerting

Your GitOps infrastructure is now ready to work with any GKE cluster in any GCP project! 