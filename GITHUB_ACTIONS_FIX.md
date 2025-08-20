# GitHub Actions Workflow Fix - Infrastructure Type Detection

## Problem Description

The GitHub Actions workflow was failing with the following error when trying to deploy the GitOps infrastructure:

```
Error: Value for undeclared variable
A variable named "sql_root_password" was assigned on the command line, but
the root module does not declare a variable of that name.
```

## Root Cause

The existing GitHub Actions workflow was designed specifically for CloudSQL deployments and was trying to pass SQL-related variables (`sql_root_password` and `sql_app_password`) to all environments, including our new GitOps infrastructure which doesn't require these variables.

## Solution Implemented

Updated the GitHub Actions workflow to automatically detect the infrastructure type and apply the appropriate deployment strategy:

### Infrastructure Type Detection

The workflow now detects infrastructure type by checking for specific files:

1. **GitOps Infrastructure**: Detected by presence of `gke.tf` or `flux-bootstrap.tf`
2. **CloudSQL Infrastructure**: Detected by presence of `google_sql_database_instance` in `main.tf`
3. **Generic Infrastructure**: Fallback for other infrastructure types

### Deployment Logic

```bash
# Detect infrastructure type by checking for specific files
if [ -f "$ENV_PATH/gke.tf" ] || [ -f "$ENV_PATH/flux-bootstrap.tf" ]; then
  echo "Detected GitOps infrastructure (GKE + FluxCD) for $ENV"
  
  # GitOps infrastructure deployment (no SQL passwords needed)
  terraform -chdir=$ENV_PATH init -lock=false
  terraform -chdir=$ENV_PATH plan -lock=false
  terraform -chdir=$ENV_PATH apply -auto-approve -lock=false
  
  echo "GitOps infrastructure for $ENV deployed successfully"
  
elif [ -f "$ENV_PATH/main.tf" ] && grep -q "google_sql_database_instance" "$ENV_PATH/main.tf"; then
  echo "Detected CloudSQL infrastructure for $ENV"
  
  # CloudSQL deployment with password variables
  ROOT_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
  APP_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
  
  terraform -chdir=$ENV_PATH init -lock=false
  terraform -chdir=$ENV_PATH plan -lock=false -var="sql_root_password=$ROOT_PASSWORD" -var="sql_app_password=$APP_PASSWORD"
  terraform -chdir=$ENV_PATH apply -auto-approve -lock=false -var="sql_root_password=$ROOT_PASSWORD" -var="sql_app_password=$APP_PASSWORD"
  
  # Store passwords for CloudSQL
  echo "$ROOT_PASSWORD" | gcloud secrets create cloudsql-root-password-$ENV --data-file=- --replication-policy="automatic" || echo "Secret already exists"
  echo "$APP_PASSWORD" | gcloud secrets create cloudsql-app-password-$ENV --data-file=- --replication-policy="automatic" || echo "Secret already exists"
  
  echo "CloudSQL infrastructure for $ENV deployed successfully"
  
else
  echo "Detected generic infrastructure for $ENV"
  
  # Generic infrastructure deployment (no specific variables)
  terraform -chdir=$ENV_PATH init -lock=false
  terraform -chdir=$ENV_PATH plan -lock=false
  terraform -chdir=$ENV_PATH apply -auto-approve -lock=false
  
  echo "Generic infrastructure for $ENV deployed successfully"
fi
```

## Benefits

1. **Backward Compatibility**: Existing CloudSQL deployments continue to work unchanged
2. **Forward Compatibility**: New GitOps infrastructure deployments work seamlessly
3. **Extensibility**: Easy to add support for other infrastructure types
4. **Error Prevention**: No more variable mismatch errors
5. **Clear Logging**: Infrastructure type is clearly identified in logs

## Files Modified

- `.github/workflows/terraform.yml`: Updated with infrastructure type detection
- `.github/workflows/terraform.yml.backup`: Backup of original workflow

## Testing

The workflow will now:

1. **Detect GitOps Infrastructure**: When `gke.tf` or `flux-bootstrap.tf` is present
2. **Deploy Without SQL Variables**: GitOps infrastructure deploys without password variables
3. **Maintain CloudSQL Support**: Existing CloudSQL deployments continue to work
4. **Handle Mixed Environments**: Can deploy both types in the same repository

## Next Steps

The updated workflow is now ready to deploy the GitOps infrastructure. When you push changes to the `environments/non-prod/dev/` directory, the workflow will:

1. Detect the GitOps infrastructure type
2. Deploy GKE cluster and FluxCD without SQL variables
3. Complete the GitOps infrastructure setup successfully

## Verification

To verify the fix worked:

1. Check the GitHub Actions logs for the message: "Detected GitOps infrastructure (GKE + FluxCD) for dev"
2. Confirm no SQL variable errors in the deployment
3. Verify successful deployment of GKE and FluxCD components

---

This fix ensures that the `das-l4-infra-np` repository can handle both CloudSQL and GitOps infrastructure deployments seamlessly within the same CI/CD pipeline. 