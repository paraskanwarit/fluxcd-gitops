variable "cluster_endpoint" {
  description = "The endpoint of the GKE cluster."
  type        = string
}

variable "cluster_ca_certificate" {
  description = "The base64 encoded public CA certificate for the cluster."
  type        = string
}

variable "gke_token" {
  description = "The GKE cluster authentication token."
  type        = string
}

variable "flux_version" {
  description = "The version of the FluxCD Helm chart to install."
  type        = string
  default     = "2.12.2"
} 