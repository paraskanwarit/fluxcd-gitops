# GKE Autopilot Terraform Module

A production-ready Terraform module for creating Google Kubernetes Engine (GKE) Autopilot clusters with enterprise-grade security and scalability features.

## Features

- **GKE Autopilot**: Fully managed Kubernetes with automatic scaling
- **Production Security**: Workload Identity, shielded nodes, and network policies
- **Enterprise Ready**: Logging, monitoring, and release channel management
- **Flexible Configuration**: Customizable network, subnetwork, and security settings
- **Zero Maintenance**: Google manages the control plane and node infrastructure

## Usage

### Basic Usage

```hcl
module "gke_autopilot" {
  source = "github.com/paraskanwarit/terraform-modules//gke-autopilot"

  name     = "my-gke-cluster"
  location = "us-central1"
  project  = "my-gcp-project"

  network    = "default"
  subnetwork = "default"
}
```

### Advanced Usage with Security Features

```hcl
module "gke_autopilot" {
  source = "github.com/paraskanwarit/terraform-modules//gke-autopilot"

  name     = "production-gke-cluster"
  location = "us-central1"
  project  = "my-gcp-project"

  network    = "vpc-network"
  subnetwork = "gke-subnet"

  release_channel = "stable"

  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/24"
      display_name = "Corporate Network"
    },
    {
      cidr_block   = "192.168.1.0/24"
      display_name = "VPN Network"
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| google | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the GKE cluster | `string` | n/a | yes |
| location | The location (region or zone) for the GKE cluster | `string` | n/a | yes |
| project | The GCP project ID | `string` | n/a | yes |
| network | The VPC network to host the cluster | `string` | `"default"` | no |
| subnetwork | The subnetwork to host the cluster | `string` | `"default"` | no |
| release_channel | The release channel of the cluster | `string` | `"regular"` | no |
| master_authorized_networks | List of master authorized networks | `list(object({cidr_block = string, display_name = string}))` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | The name of the GKE cluster |
| cluster_endpoint | The IP address of the cluster master |
| cluster_ca_certificate | The cluster CA certificate (base64 encoded) |
| cluster_id | The ID of the GKE cluster |

## Security Features

### Workload Identity
- Automatically enabled for secure pod-to-GCP service authentication
- Eliminates the need for service account keys

### Shielded Nodes
- Automatically enabled in Autopilot mode
- Provides advanced security and integrity monitoring

### Master Authorized Networks
- Optional feature to restrict access to the control plane
- Only specified CIDR blocks can access the Kubernetes API

### Logging and Monitoring
- Kubernetes logs sent to Cloud Logging
- Metrics sent to Cloud Monitoring
- Enables comprehensive observability

## Best Practices

1. **Use Release Channels**: Choose `stable` for production workloads
2. **Network Security**: Use custom VPC networks with proper subnets
3. **Access Control**: Configure master authorized networks for production
4. **Monitoring**: Enable logging and monitoring for observability
5. **Naming**: Use descriptive names for easy identification

## Examples

See the `examples/` directory for complete working examples:

- [Basic Cluster](examples/basic/)
- [Production Cluster](examples/production/)
- [Multi-Region Cluster](examples/multi-region/)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See LICENSE file for details. 