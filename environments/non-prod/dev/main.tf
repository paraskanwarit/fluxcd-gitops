# Main Terraform Configuration for Dev Environment
# This file orchestrates the deployment of GKE and FluxCD

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

# Google Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Local state outputs for debugging
output "environment_info" {
  description = "Environment information"
  value = {
    project_id   = var.project_id
    region       = var.region
    cluster_name = var.cluster_name
    environment  = "dev"
  }
}

# Output all cluster information
output "cluster_info" {
  description = "Complete cluster information"
  value = {
    name     = module.gke_autopilot.name
    endpoint = module.gke_autopilot.endpoint
    id       = module.gke_autopilot.id
  }
  depends_on = [module.gke_autopilot]
}

# Output FluxCD information
# FluxCD is installed but not managed by Terraform
output "flux_info" {
  description = "FluxCD installation information"
  value = {
    installed = "deployed"
    namespace = "flux-system"
    version   = var.flux_version
  }
} 