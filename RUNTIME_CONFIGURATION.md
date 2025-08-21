# Runtime Configuration Guide

This guide shows you the different ways to provide configuration variables at runtime, making your GitOps setup extremely flexible.

## 🚀 **Command Line Override (Most Flexible)**

### **Basic Override**
```bash
# Override any variable at runtime
terraform plan \
  -var="project_id=my-new-project" \
  -var="region=us-west1" \
  -var="cluster_name=prod-cluster"

# Apply with overrides
terraform apply \
  -var="project_id=my-new-project" \
  -var="region=us-west1" \
  -var="cluster_name=prod-cluster"
```

### **Advanced Override with Environment**
```bash
# Create a new environment on-the-fly
terraform -chdir=environments/non-prod/dev plan \
  -var="project_id=my-new-project" \
  -var="region=europe-west1" \
  -var="cluster_name=eu-cluster" \
  -var="flux_version=2.12.2"
```

## 🌍 **Environment Variables**

### **Set Variables Before Running**
```bash
# Set environment variables
export TF_VAR_project_id="my-new-project"
export TF_VAR_region="us-west1"
export TF_VAR_cluster_name="prod-cluster"
export TF_VAR_flux_version="2.12.2"

# Run normally - Terraform picks up environment variables
terraform plan
terraform apply
```

### **One-Line Environment Variable Override**
```bash
# Override for single command
TF_VAR_project_id="my-new-project" \
TF_VAR_region="us-west1" \
TF_VAR_cluster_name="prod-cluster" \
terraform plan
```

## 📁 **Variable Files (Different per Environment)**

### **Create Multiple Environment Configs**
```bash
# Copy template for different environments
cp config-template.tfvars environments/non-prod/dev/terraform.tfvars
cp config-template.tfvars environments/non-prod/staging/terraform.tfvars
cp config-template.tfvars environments/prod/prod/terraform.tfvars

# Edit each with different values
```

### **Environment-Specific Configs**
```bash
# dev/terraform.tfvars
project_id = "dev-project"
region = "us-central1"
cluster_name = "dev-cluster"

# staging/terraform.tfvars
project_id = "staging-project"
region = "us-west1"
cluster_name = "staging-cluster"

# prod/terraform.tfvars
project_id = "prod-project"
region = "europe-west1"
cluster_name = "prod-cluster"
```

## 🔧 **Enhanced Setup Script Usage**

### **Command Line Mode**
```bash
# Quick setup with command line arguments
./scripts/setup-new-project.sh \
  -p "my-new-project" \
  -r "us-west1" \
  -c "prod-cluster" \
  -g "myusername" \
  -e "prod"

# Or use long options
./scripts/setup-new-project.sh \
  --project "my-new-project" \
  --region "us-west1" \
  --cluster "prod-cluster" \
  --github "myusername" \
  --environment "prod"
```

### **Interactive Mode**
```bash
# Run without arguments for interactive mode
./scripts/setup-new-project.sh
```

## 📋 **Real-World Examples**

### **Example 1: Quick Project Switch**
```bash
# Switch to a different project temporarily
terraform plan \
  -var="project_id=my-other-project" \
  -var="region=us-east1" \
  -var="cluster_name=test-cluster"
```

### **Example 2: Multi-Region Deployment**
```bash
# Deploy to US West
terraform -chdir=environments/non-prod/us-west apply \
  -var="region=us-west1" \
  -var="cluster_name=us-west-cluster"

# Deploy to Europe
terraform -chdir=environments/non-prod/europe apply \
  -var="region=europe-west1" \
  -var="cluster_name=eu-cluster"
```

### **Example 3: Environment Promotion**
```bash
# Promote from dev to staging
cp environments/non-prod/dev/terraform.tfvars environments/non-prod/staging/
# Edit staging/terraform.tfvars with staging values

# Then apply
terraform -chdir=environments/non-prod/staging apply
```

## 🎯 **Best Practices**

### **1. Use Command Line for One-Time Overrides**
```bash
# Perfect for testing different configurations
terraform plan -var="region=us-west1"
```

### **2. Use Environment Variables for Session-Wide Settings**
```bash
# Set once, use for entire session
export TF_VAR_project_id="my-project"
export TF_VAR_region="us-central1"
```

### **3. Use Variable Files for Persistent Configurations**
```bash
# Best for different environments
environments/non-prod/dev/terraform.tfvars
environments/non-prod/staging/terraform.tfvars
environments/prod/prod/terraform.tfvars
```

### **4. Use the Setup Script for New Environments**
```bash
# Automates the entire process
./scripts/setup-new-project.sh -p "new-project" -r "us-west1"
```

## 🔍 **Variable Precedence**

Terraform uses this order (highest to lowest priority):

1. **Command line flags** (`-var`)
2. **Environment variables** (`TF_VAR_*`)
3. **Variable files** (`*.tfvars`)
4. **Default values** (in `variables.tf`)

## 📚 **Quick Reference Commands**

```bash
# Show all available variables
terraform -chdir=environments/non-prod/dev variables

# Plan with specific variables
terraform -chdir=environments/non-prod/dev plan \
  -var="project_id=my-project" \
  -var="region=us-west1"

# Apply with environment variables
TF_VAR_project_id="my-project" \
TF_VAR_region="us-west1" \
terraform -chdir=environments/non-prod/dev apply

# Use the setup script
./scripts/setup-new-project.sh -h  # Show help
./scripts/setup-new-project.sh -p "project" -r "region" -c "cluster"
```

## 🎉 **Benefits of Runtime Configuration**

- **No file editing required** for quick changes
- **Perfect for CI/CD pipelines** where variables come from environment
- **Easy project switching** without modifying files
- **Environment-specific configurations** without duplication
- **Maximum flexibility** for different deployment scenarios

Your GitOps setup is now incredibly flexible and can work with any GKE cluster in any region with just command line arguments! 