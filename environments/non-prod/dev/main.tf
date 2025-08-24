# main.tf
# Main Terraform configuration for the dev environment
# This configuration uses data sources to work with existing GKE infrastructure

# Configure the Google Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Configure the Google Beta Provider (if needed for advanced features)
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Data source to get existing GKE cluster information
data "google_container_cluster" "existing_cluster" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id
}

# Data source to get current Google client configuration
data "google_client_config" "current" {}

# Output environment information
output "environment" {
  description = "Environment details"
  value = {
    name        = "dev"
    project_id  = var.project_id
    region      = var.region
    cluster_name = var.cluster_name
  }
}

# Output cluster information
output "cluster" {
  description = "GKE cluster information"
  value = {
    name           = data.google_container_cluster.existing_cluster.name
    endpoint       = data.google_container_cluster.existing_cluster.endpoint
    id             = data.google_container_cluster.existing_cluster.id
    location       = data.google_container_cluster.existing_cluster.location
    project        = data.google_container_cluster.existing_cluster.project
    version        = data.google_container_cluster.existing_cluster.master_version
  }
}

# Output FluxCD information (hardcoded since it's managed independently)
output "flux_info" {
  description = "FluxCD installation information"
  value = {
    installed = "deployed"
    namespace = "flux-system"
    version   = var.flux_version
  }
} 