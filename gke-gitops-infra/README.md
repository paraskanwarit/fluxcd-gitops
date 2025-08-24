# GKE GitOps Infra

This repository contains the infrastructure-as-code setup for provisioning a Google Kubernetes Engine (GKE) Autopilot cluster and bootstrapping FluxCD for GitOps-based application delivery.

## Structure

- `environment/non-prod/dev/`: Environment-specific Terraform code to provision a dev GKE cluster using remote module.
- `flux-bootstrap/`: Terraform code to bootstrap FluxCD onto the cluster.

## Usage

1. Configure your GCP credentials and backend.
2. Deploy the GKE cluster using Terraform in `environment/non-prod/dev/`.
3. Bootstrap FluxCD using Terraform in `flux-bootstrap/`.
4. Use FluxCD to deploy applications via Helm charts and GitOps.

See each subdirectory for more details and instructions. 

## Diagram

See [diagram.md](./diagram.md) for a visual overview of the end-to-end GitOps flow.

## Next Steps

1. Create a Helm chart for your application (see `sample-app-helm-chart` repo).
2. Create a FluxCD delivery repo with HelmRelease manifests (see `flux-app-delivery` repo).
3. Configure FluxCD to watch the delivery repo for automated deployments. 