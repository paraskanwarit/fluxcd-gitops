# GKE Autopilot Terraform Module

This module provisions a Google Kubernetes Engine (GKE) Autopilot cluster with production-ready defaults.

## Usage

```hcl
module "gke" {
  source     = "../terraform-modules/gke"
  name       = "my-gke-cluster"
  location   = "us-central1"
  project    = "my-gcp-project"
  network    = "default"
  subnetwork = "default"
}
```

## Variables
- `name`: The name of the GKE cluster.
- `location`: The region or zone for the cluster.
- `project`: The GCP project ID.
- `network`: The VPC network name.
- `subnetwork`: The subnetwork name.
- `release_channel`: GKE release channel (default: REGULAR).
- `master_authorized_networks`: (Optional) List of CIDR blocks for master authorized networks.

## Outputs
- `name`: Cluster name
- `endpoint`: Cluster endpoint
- `ca_certificate`: Cluster CA cert
- `id`: Cluster ID 