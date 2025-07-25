# Dev Environment: GKE Autopilot Cluster

This directory provisions a GKE Autopilot cluster in the non-prod/dev environment using the reusable Terraform module.

## Usage

1. Set up your GCP credentials (e.g., `gcloud auth application-default login`).
2. Initialize Terraform:
   ```sh
   terraform init
   ```
3. Plan and apply:
   ```sh
   terraform plan -var="project=YOUR_GCP_PROJECT_ID"
   terraform apply -var="project=YOUR_GCP_PROJECT_ID"
   ```

## Variables
- `project`: (required) GCP project ID
- `region`: (default: us-central1)
- `cluster_name`: (default: dev-gke-autopilot)
- `network`: (default: default)
- `subnetwork`: (default: default)
- `master_authorized_networks`: (optional)

## Outputs
- `cluster_name`: Cluster name
- `cluster_endpoint`: Cluster endpoint
- `cluster_ca_certificate`: Cluster CA cert 