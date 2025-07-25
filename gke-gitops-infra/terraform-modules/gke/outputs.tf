output "name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.this.name
}

output "endpoint" {
  description = "The endpoint of the GKE cluster."
  value       = google_container_cluster.this.endpoint
}

output "ca_certificate" {
  description = "The base64 encoded public CA certificate for the cluster."
  value       = google_container_cluster.this.master_auth.0.cluster_ca_certificate
}

output "id" {
  description = "The ID of the GKE cluster."
  value       = google_container_cluster.this.id
} 