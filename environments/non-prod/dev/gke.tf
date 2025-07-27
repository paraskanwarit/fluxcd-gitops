# GKE Autopilot Cluster Configuration
# This file provisions a GKE Autopilot cluster for the dev environment

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# GKE Autopilot Cluster
module "gke_autopilot" {
  source = "github.com/paraskanwarit/terraform-modules//gke-autopilot"

  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  network    = var.network
  subnetwork = var.subnetwork

  release_channel = var.release_channel

  # Using default GCP public CIDRs access (gcpPublicCidrsAccessEnabled: true)
  # master_authorized_networks = var.master_authorized_networks
}

# Outputs for use by other modules (like flux-bootstrap)
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

output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = module.gke_autopilot.cluster_id
} 