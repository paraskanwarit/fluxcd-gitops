output "cluster_name" {
  value       = module.gke.name
  description = "The name of the GKE cluster."
}

output "cluster_endpoint" {
  value       = module.gke.endpoint
  description = "The endpoint of the GKE cluster."
}

output "cluster_ca_certificate" {
  value       = module.gke.ca_certificate
  description = "The base64 encoded public CA certificate for the cluster."
} 