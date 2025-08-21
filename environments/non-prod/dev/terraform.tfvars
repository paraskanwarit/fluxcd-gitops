# Configuration for existing GKE cluster
# These values are used by data sources to fetch cluster information

project_id = "extreme-gecko-466211-t1"
region     = "us-central1"
cluster_name = "dev-gke-autopilot"

# FluxCD Configuration
flux_version = "2.12.2"

# Note: The following variables are not used when working with existing clusters
# They are kept for reference but have no effect on data source operations
# network = "default"
# subnetwork = "default"
# release_channel = "REGULAR"
# master_authorized_networks = [...] 