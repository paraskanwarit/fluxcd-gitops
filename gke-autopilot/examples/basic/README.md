# Basic GKE Autopilot Cluster Example

This example demonstrates how to create a basic GKE Autopilot cluster with default settings.

## Features

- GKE Autopilot cluster with default network
- Automatic scaling and management
- Workload Identity enabled
- Logging and monitoring enabled

## Usage

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Update the variables:**
   Edit `terraform.tfvars` and set your GCP project ID and other values.

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan the deployment:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Requirements

- GCP project with billing enabled
- Kubernetes Engine API enabled
- Terraform >= 1.0
- Google provider >= 4.0

## Outputs

- `cluster_name`: The name of the GKE cluster
- `cluster_endpoint`: The IP address of the cluster master
- `cluster_ca_certificate`: The cluster CA certificate (base64 encoded)

## Clean Up

To destroy the resources:
```bash
terraform destroy
``` 