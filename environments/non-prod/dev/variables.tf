# Variables for GKE and FluxCD Configuration

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

variable "network" {
  description = "The VPC network to host the cluster"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster"
  type        = string
  default     = "default"
}

variable "release_channel" {
  description = "The release channel of the cluster"
  type        = string
  default     = "regular"
}

variable "master_authorized_networks" {
  description = "List of master authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "All Networks (Dev Environment)"
    }
  ]
}

variable "flux_version" {
  description = "The version of FluxCD to install"
  type        = string
  default     = "2.12.2"
} 