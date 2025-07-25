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
  project = var.project
  region  = var.region
}

module "gke" {
  source     = "../../../terraform-modules/gke"
  name       = var.cluster_name
  location   = var.region
  project    = var.project
  network    = var.network
  subnetwork = var.subnetwork
  # Optionally, set master_authorized_networks
  # master_authorized_networks = var.master_authorized_networks
} 