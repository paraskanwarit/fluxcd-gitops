# Production GKE Autopilot Cluster Example

This example demonstrates how to create a production-ready GKE Autopilot cluster with enterprise-grade security features.

## Features

- **Custom VPC Network**: Dedicated network for the cluster
- **Production Security**: Master authorized networks for control plane access
- **Stable Release Channel**: For production stability
- **Network Monitoring**: Flow logs enabled for security monitoring
- **Workload Identity**: Secure pod-to-GCP service authentication
- **Logging and Monitoring**: Comprehensive observability

## Security Features

### Master Authorized Networks
Restricts access to the Kubernetes control plane to specified CIDR blocks only.

### Custom VPC
Isolates the cluster in a dedicated network with proper subnet configuration.

### Flow Logs
Enables network flow monitoring for security and compliance.

## Usage

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Update the variables:**
   Edit `terraform.tfvars` and set your GCP project ID and network CIDRs.

3. **Configure Master Authorized Networks:**
   Update the `master_authorized_networks` variable with your actual network CIDRs.

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```

5. **Plan the deployment:**
   ```bash
   terraform plan
   ```

6. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Requirements

- GCP project with billing enabled
- Kubernetes Engine API enabled
- Compute Engine API enabled
- Terraform >= 1.0
- Google provider >= 4.0

## Outputs

- `cluster_name`: The name of the GKE cluster
- `cluster_endpoint`: The IP address of the cluster master
- `cluster_ca_certificate`: The cluster CA certificate (base64 encoded)
- `vpc_name`: The name of the VPC network
- `subnet_name`: The name of the subnet

## Production Considerations

1. **Network Security**: Update master authorized networks with your actual network ranges
2. **Monitoring**: Enable additional monitoring and alerting
3. **Backup**: Configure backup strategies for your applications
4. **Compliance**: Ensure the setup meets your compliance requirements
5. **Scaling**: Monitor and adjust resources as needed

## Clean Up

To destroy the resources:
```bash
terraform destroy
```

**Warning**: This will delete the VPC network and all associated resources. 