# GitOps Infrastructure with GKE and FluxCD

This repository contains a complete GitOps infrastructure setup using Google Kubernetes Engine (GKE) Autopilot and FluxCD for continuous delivery.

## Overview

This project demonstrates a production-ready GitOps pipeline that:
- Uses existing GKE infrastructure (no cluster creation)
- Bootstraps FluxCD for GitOps continuous delivery
- Deploys sample applications via Helm charts
- Integrates with GitHub Actions for CI/CD automation

## Architecture

The solution follows a multi-repository GitOps pattern:

1. **Infrastructure Repository** (this repo): Contains Terraform configurations and FluxCD manifests
2. **Helm Chart Repository**: Contains application Helm charts
3. **Flux Delivery Repository**: Contains FluxCD manifests for application deployment

## Key Components

- **GKE Autopilot**: Managed Kubernetes cluster with automatic scaling
- **FluxCD v2**: GitOps continuous delivery tool
- **Terraform**: Infrastructure as Code for GCP resources
- **Helm**: Package manager for Kubernetes applications
- **GitHub Actions**: CI/CD automation

## Quick Start

### Prerequisites

- GCP project with billing enabled
- GKE cluster already running
- kubectl configured for cluster access
- Terraform installed
- Flux CLI installed

### Setup Steps

1. **Clone this repository**:
   ```bash
   git clone https://github.com/paraskanwarit/fluxcd-gitops.git
   cd fluxcd-gitops
   ```

2. **Run the complete setup script**:
   ```bash
   ./scripts/complete-setup.sh
   ```

3. **Verify deployment**:
   ```bash
   kubectl get pods -A
   kubectl get helmrelease -A
   ```

## Repository Structure

```
fluxcd-gitops/
├── environments/
│   └── non-prod/
│       └── dev/
│           ├── main.tf                 # Main Terraform config
│           ├── backend.tf              # GCS backend configuration
│           ├── variables.tf            # Environment variables
│           ├── terraform.tfvars        # Variable values
│           └── flux-bootstrap.tf.example # Optional FluxCD bootstrap
├── flux-app-delivery/                  # FluxCD application manifests
├── sample-app-helm-chart/             # Sample application Helm chart
├── scripts/                           # Automation scripts
└── docs/                             # Documentation
```

## Configuration

### Environment Variables

Update `environments/non-prod/dev/terraform.tfvars` with your values:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
cluster_name = "your-gke-cluster-name"
```

### FluxCD Bootstrap

To enable automatic FluxCD installation:

1. Copy the example file:
   ```bash
   cp environments/non-prod/dev/flux-bootstrap.tf.example \
      environments/non-prod/dev/flux-bootstrap.tf
   ```

2. Apply the configuration:
   ```bash
   cd environments/non-prod/dev
   terraform apply
   ```

## Usage

### Deploying Applications

1. **Update Helm chart version** in `sample-app-helm-chart/charts/sample-app/Chart.yaml`
2. **Update HelmRelease version** in `flux-app-delivery/helmrelease/sample-app-helmrelease.yaml`
3. **Commit and push** changes to trigger GitOps reconciliation

### Monitoring

- **FluxCD status**: `kubectl get helmrelease -A`
- **Application logs**: `kubectl logs -n sample-app -l app=sample-app`
- **FluxCD logs**: `kubectl logs -n flux-system deployment/helm-controller`

## Troubleshooting

### Common Issues

1. **Port-forward fails**: Ensure no other processes are using port 8080
2. **FluxCD reconciliation fails**: Check Helm chart versions and repository access
3. **Terraform plan shows changes**: Verify cluster name and region match existing infrastructure

### Debug Commands

```bash
# Check cluster connectivity
kubectl cluster-info

# Verify FluxCD installation
kubectl get deployment -n flux-system

# Check application status
kubectl get pods -n sample-app

# View FluxCD logs
kubectl logs -n flux-system deployment/helm-controller
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Check the troubleshooting section
- Review FluxCD documentation
- Open a GitHub issue

## References

- [FluxCD Documentation](https://fluxcd.io/docs/)
- [GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)