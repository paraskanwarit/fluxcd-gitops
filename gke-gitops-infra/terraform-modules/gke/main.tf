// GKE Autopilot Cluster Module

resource "google_container_cluster" "this" {
  name     = var.name
  location = var.location
  project  = var.project

  enable_autopilot = true

  release_channel {
    channel = var.release_channel
  }

  network    = var.network
  subnetwork = var.subnetwork

  ip_allocation_policy {}

  # Enable Shielded Nodes for security
  # Shielded Nodes are always enabled in Autopilot mode; do not set enable_shielded_nodes

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  # Logging and Monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Master authorized networks (optional, for extra security)
  dynamic "master_authorized_networks_config" {
    for_each = var.master_authorized_networks != null ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }
} 