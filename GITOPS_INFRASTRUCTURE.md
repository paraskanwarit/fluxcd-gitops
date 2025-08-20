# GitOps Infrastructure with GKE and FluxCD

This document describes the GitOps infrastructure setup in the `das-l4-infra-np` repository, which provides a complete end-to-end GitOps solution using Google Kubernetes Engine (GKE) Autopilot and FluxCD.

## Architecture Overview

The GitOps infrastructure consists of:

- **GKE Autopilot Cluster**: Production-ready Kubernetes cluster with automatic scaling
- **FluxCD**: GitOps continuous delivery platform for Kubernetes
- **Remote State Management**: GCS backend for Terraform state
- **GitHub Actions CI/CD**: Automated deployment pipeline

## Repository Structure

```
das-l4-infra-np/
├── .github/workflows/
│   └── terraform.yml          # Main deployment workflow
├── environments/
│   └── non-prod/
│       └── dev/               # Development environment
│           ├── main.tf        # Main Terraform configuration
│           ├── gke.tf         # GKE cluster configuration
│           ├── flux-bootstrap.tf # FluxCD installation
│           ├── variables.tf   # Variable definitions
│           ├── backend.tf     # Remote state configuration
│           └── terraform.tfvars # Environment variables
├── GITOPS_INFRASTRUCTURE.md   # This documentation
└── README.md                  # Main repository documentation
```

## Infrastructure Components

### 1. GKE Autopilot Cluster (`gke.tf`)

The GKE cluster is provisioned using the reusable module from the `terraform-modules` repository:

```hcl
module "gke_autopilot" {
  source = "github.com/paraskanwarit/terraform-modules//gke-autopilot"

  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  network    = var.network
  subnetwork = var.subnetwork

  release_channel = var.release_channel
  master_authorized_networks = var.master_authorized_networks
}
```

**Features:**
- GKE Autopilot with automatic scaling
- Workload Identity enabled
- Production security features
- Logging and monitoring enabled
- Master authorized networks support

### 2. FluxCD Bootstrap (`flux-bootstrap.tf`)

FluxCD is installed on the GKE cluster using Helm:

```hcl
resource "helm_release" "flux" {
  name       = "flux"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  version    = var.flux_version
  namespace  = "flux-system"
  create_namespace = true

  depends_on = [data.google_container_cluster.gke]
}
```

**Features:**
- FluxCD v2.12.2 installation
- CRDs automatically installed
- Network policies enabled
- Metrics and events enabled
- Proper dependency management

### 3. Remote State Management (`backend.tf`)

Terraform state is stored in Google Cloud Storage:

```hcl
terraform {
  backend "gcs" {
    bucket  = "terraform-statefile-np"
    prefix  = "dev/terraform/state"
  }
}
```

**Benefits:**
- State locking for concurrent operations
- Version history and rollback capability
- Team collaboration support
- Secure state storage

## Environment Configuration

### Development Environment (`environments/non-prod/dev/`)

**Variables:**
- `project_id`: "extreme-gecko-466211-t1"
- `region`: "us-central1"
- `cluster_name`: "dev-gke-autopilot"
- `flux_version`: "2.12.2"
- `release_channel`: "REGULAR"

**Security:**
- Master authorized networks: All networks (0.0.0.0/0) for dev
- Workload Identity enabled
- Shielded nodes enabled

## Deployment Process

### 1. Automated Deployment via GitHub Actions

The existing GitHub Actions workflow in `.github/workflows/terraform.yml` automatically:

1. **Detects Environment Changes**: Monitors the `environments/` directory
2. **Initializes Terraform**: Sets up providers and modules
3. **Plans Changes**: Shows what will be deployed
4. **Applies Infrastructure**: Deploys GKE and FluxCD
5. **Stores State**: Saves state to GCS bucket

### 2. Manual Deployment

For manual deployment:

```bash
# Navigate to environment
cd environments/non-prod/dev

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply changes
terraform apply
```

## State Migration

The existing GKE cluster state has been migrated from the local state to the GCS backend:

- **Source**: Local state from `fluxcd-gitops` project
- **Destination**: GCS bucket `terraform-statefile-np`
- **Prefix**: `dev/terraform/state`
- **Status**: ✅ Successfully migrated

## Dependencies and Order

The infrastructure deployment follows this order:

1. **GKE Cluster**: Provisioned first using the terraform-modules
2. **FluxCD**: Installed after GKE cluster is ready
3. **Dependencies**: Proper `depends_on` relationships ensure correct order

## Integration with Existing Workflow

This GitOps infrastructure integrates seamlessly with the existing `das-l4-infra-np` workflow:

- **Same CI/CD Pipeline**: Uses existing GitHub Actions workflow
- **Same State Management**: Uses existing GCS bucket
- **Same Security Model**: Uses existing Workload Identity Federation
- **Same Environment Structure**: Follows existing environment patterns

## Next Steps

### 1. Application Deployment

After the infrastructure is deployed, you can deploy applications using:

- **Helm Charts**: Store in separate repositories
- **FluxCD Manifests**: GitRepository and HelmRelease resources
- **GitOps Workflow**: Push to Git to trigger deployment

### 2. Production Environment

Create a production environment following the same pattern:

```bash
# Copy dev environment
cp -r environments/non-prod/dev environments/production/prod

# Update variables for production
# - Restrict master authorized networks
# - Use STABLE release channel
# - Configure production security settings
```

### 3. Monitoring and Observability

- **GKE Monitoring**: Already enabled
- **FluxCD Metrics**: Available at `/metrics` endpoint
- **Logging**: Cloud Logging integration
- **Alerting**: Set up alerts for cluster and FluxCD health

## Troubleshooting

### Common Issues

1. **State Lock Issues**
   ```bash
   terraform force-unlock <lock-id>
   ```

2. **FluxCD Installation Issues**
   ```bash
   kubectl get pods -n flux-system
   kubectl logs -n flux-system deployment/helm-controller
   ```

3. **GKE Access Issues**
   ```bash
   gcloud container clusters get-credentials dev-gke-autopilot --region us-central1
   ```

### Verification Commands

```bash
# Check GKE cluster status
gcloud container clusters describe dev-gke-autopilot --region us-central1

# Check FluxCD status
kubectl get pods -n flux-system

# Check Terraform state
terraform state list
terraform output
```

## Security Considerations

- **Master Authorized Networks**: Currently open for dev (restrict for production)
- **Workload Identity**: Enabled for secure pod-to-GCP authentication
- **Network Policies**: Enabled in FluxCD installation
- **State Security**: Stored in GCS with proper access controls

## Cost Optimization

- **GKE Autopilot**: Automatic scaling reduces costs
- **Node Pools**: Scale to zero when not in use
- **Monitoring**: Use Cloud Monitoring for cost tracking

## Support and Maintenance

- **Updates**: GKE updates handled automatically via release channels
- **FluxCD Updates**: Update `flux_version` variable and apply
- **Backup**: State automatically backed up in GCS
- **Rollback**: Use Terraform state history for rollbacks

---

This GitOps infrastructure provides a solid foundation for deploying and managing Kubernetes applications with full automation and Git-based workflows. 