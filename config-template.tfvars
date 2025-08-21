# Configuration Template for New Projects
# Copy this file to environments/non-prod/dev/terraform.tfvars and update the values

# GCP Project Configuration
project_id = "your-gcp-project-id"
region     = "your-gke-cluster-region"
cluster_name = "your-gke-cluster-name"

# FluxCD Configuration
flux_version = "2.12.2"

# Network Configuration (optional - comment out if using default)
# network = "your-vpc-network-name"
# subnetwork = "your-subnetwork-name"

# Master Authorized Networks (optional - comment out if using public access)
# master_authorized_networks = [
#   {
#     cidr_block   = "0.0.0.0/0"
#     display_name = "Public Access"
#   }
# ]

# Release Channel (REGULAR, RAPID, STABLE, EXTENDED)
release_channel = "REGULAR" 