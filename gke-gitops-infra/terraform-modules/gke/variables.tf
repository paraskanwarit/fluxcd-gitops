variable "name" {
  description = "The name of the GKE cluster."
  type        = string
}

variable "location" {
  description = "The location (region or zone) for the cluster."
  type        = string
}

variable "project" {
  description = "The GCP project ID."
  type        = string
}

variable "network" {
  description = "The VPC network to host the cluster in."
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster in."
  type        = string
}

variable "release_channel" {
  description = "The release channel for GKE (RAPID, REGULAR, STABLE)."
  type        = string
  default     = "REGULAR"
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks for master authorized networks. Optional."
  type        = list(object({ cidr_block = string, display_name = string }))
  default     = null
} 