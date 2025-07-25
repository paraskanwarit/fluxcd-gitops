# FluxCD Bootstrap with Terraform

This directory contains Terraform code to install FluxCD on your GKE cluster using the official Helm chart.

## Prerequisites
- GKE cluster is provisioned and kubeconfig/token is available.
- The following variables are required:
  - `cluster_endpoint`: GKE cluster endpoint (from environment outputs)
  - `cluster_ca_certificate`: GKE cluster CA cert (from environment outputs)
  - `gke_token`: GKE cluster access token (see below)

## Usage

1. Obtain a GKE access token:
   ```sh
   gcloud auth print-access-token
   ```
2. Run Terraform:
   ```sh
   terraform init
   terraform apply \
     -var="cluster_endpoint=..." \
     -var="cluster_ca_certificate=..." \
     -var="gke_token=$(gcloud auth print-access-token)"
   ```

## What This Does
- Installs FluxCD in the `flux-system` namespace using the official Helm chart.
- Enables CRDs, metrics, events, and network policies for production readiness.

## Next Steps
- Configure FluxCD to watch your GitOps repo for application delivery. 