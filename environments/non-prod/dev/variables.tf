# Variables for existing GKE cluster and FluxCD configuration

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "dev-gke-autopilot"
}

variable "flux_version" {
  description = "The version of FluxCD to install"
  type        = string
  default     = "2.12.2"
}

# Note: The following variables are not used when working with existing clusters
# They are kept for reference but have no effect on data source operations
# variable "network" { ... }
# variable "subnetwork" { ... }
# variable "release_channel" { ... }
# variable "master_authorized_networks" { ... } 