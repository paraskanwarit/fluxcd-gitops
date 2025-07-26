# Basic GKE Autopilot Cluster Example
# This example creates a simple GKE Autopilot cluster with default settings

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "gke_autopilot" {
  source = "../../"

  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  network    = "default"
  subnetwork = "default"
}

# Output the cluster details
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke_autopilot.cluster_name
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = module.gke_autopilot.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = module.gke_autopilot.cluster_ca_certificate
  sensitive   = true
} 