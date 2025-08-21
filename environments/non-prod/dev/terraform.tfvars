# Common variables for dev environment
# Update these values according to your GCP project

project_id = "extreme-gecko-466211-t1"
region     = "us-central1"

# GKE Configuration
cluster_name = "dev-gke-autopilot"
network      = "default"
subnetwork   = "default"

# Release channel for GKE (must be uppercase)
release_channel = "REGULAR"

# FluxCD Configuration
flux_version = "2.12.2"

# Master authorized networks (for dev environment, allowing all networks)
# For production, restrict this to specific CIDR blocks
master_authorized_networks = [
  {
    cidr_block   = "0.0.0.0/0"
    display_name = "All Networks (Dev Environment)"
  }
] 