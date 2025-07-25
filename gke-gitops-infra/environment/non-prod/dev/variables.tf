variable "project" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The region for the GKE cluster."
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
  default     = "dev-gke-autopilot"
}

variable "network" {
  description = "The VPC network name."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The subnetwork name."
  type        = string
  default     = "default"
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks for master authorized networks. Optional."
  type        = list(object({ cidr_block = string, display_name = string }))
  default     = null
} 