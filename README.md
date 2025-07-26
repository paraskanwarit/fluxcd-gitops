# GitOps Demo with FluxCD and GKE

A complete end-to-end GitOps demonstration using Terraform, Google Kubernetes Engine (GKE), FluxCD, and Helm.

## Architecture Overview

This project demonstrates a production-ready GitOps pipeline with:

- **Infrastructure as Code**: GKE Autopilot cluster provisioned via Terraform
- **GitOps Platform**: FluxCD v2.12.2 for continuous deployment
- **Application Packaging**: Helm charts for application deployment
- **Multi-Repository Architecture**: Separate repos for infrastructure, application, and delivery

## Repository Structure

```
fluxcd-gitops/
├── gke-gitops-infra/           # Infrastructure repository
│   ├── environment/non-prod/dev/ # Environment-specific config
│   └── flux-bootstrap/         # FluxCD installation
├── sample-app-helm-chart/      # Application Helm chart repository
│   └── charts/sample-app/      # NGINX demo application
└── flux-app-delivery/          # FluxCD delivery repository
    ├── namespaces/             # Kubernetes namespaces
    └── helmrelease/            # FluxCD HelmRelease manifests

Note: GKE module is now in separate repository: https://github.com/paraskanwarit/terraform-modules
```

## Quick Start

### Prerequisites

- Google Cloud CLI (`gcloud`) configured
- Terraform installed
- kubectl installed
- Git access to GitHub repositories

### One-Command Setup

```bash
# Run the complete setup script
./scripts/complete-setup.sh
```

## GitOps Promotion Process

### Making Changes to Your Application

When you want to make changes to your application (like updating the demo page content), follow this proper GitOps workflow:

#### Step 1: Update Your Application Code

1. **Navigate to the Helm Chart Repository**
   ```bash
   cd sample-app-helm-chart
   ```

2. **Make Your Changes**
   - Edit files in `charts/sample-app/templates/`
   - Update the ConfigMap content in `charts/sample-app/templates/configmap.yaml`
   - Modify any other application files as needed

3. **Update Chart Version**
   ```bash
   # Edit charts/sample-app/Chart.yaml
   # Change version: 0.1.1 to version: 0.1.2 (or next version)
   ```

#### Step 2: Update HelmRelease Version

1. **Navigate to the Delivery Repository**
   ```bash
   cd ../flux-app-delivery
   ```

2. **Update HelmRelease Version**
   ```bash
   # Edit helmrelease/sample-app-helmrelease.yaml
   # Change version: "0.1.1" to version: "0.1.2"
   ```

#### Step 3: Commit and Push Changes

1. **Commit Helm Chart Changes**
   ```bash
   cd ../sample-app-helm-chart
   git add .
   git commit -m "Update demo page content - version 0.1.2"
   git push origin main
   ```

2. **Commit Delivery Changes**
   ```bash
   cd ../flux-app-delivery
   git add .
   git commit -m "Update HelmRelease to version 0.1.2"
   git push origin main
   ```

#### Step 4: Monitor the GitOps Pipeline

1. **Check GitRepository Status**
   ```bash
   kubectl get gitrepository -n flux-system sample-app-helm-chart -o jsonpath='{.status.artifact.revision}'
   ```

2. **Monitor FluxCD Reconciliation**
   ```bash
   kubectl logs -n flux-system deployment/helm-controller -f
   ```

3. **Watch Pod Updates**
   ```bash
   kubectl get pods -n sample-app -w
   ```

#### Step 5: Verify Deployment

1. **Check Application Status**
   ```bash
   kubectl get helmrelease -n sample-app sample-app2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
   ```

2. **Test the Application**
   ```bash
   kubectl port-forward -n sample-app svc/sample-app2-sample-app 8080:80 &
   curl http://localhost:8080
   ```

### Quick Reference Commands

#### Status Check
```bash
echo "=== GitOps Status ==="
echo "GitRepository:"
kubectl get gitrepository -n flux-system sample-app-helm-chart -o jsonpath='{.status.artifact.revision}'
echo ""
echo "HelmRelease:"
kubectl get helmrelease -n sample-app sample-app2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
echo ""
echo "Pods:"
kubectl get pods -n sample-app
```

#### Troubleshooting
```bash
# Check FluxCD logs
kubectl logs -n flux-system deployment/helm-controller --tail=20

# Force reconciliation (if needed)
kubectl patch helmrelease -n sample-app sample-app2 --type='merge' -p='{"metadata":{"annotations":{"fluxcd.io/reconcile":"true"}}}'

# Check application logs
kubectl logs -n sample-app deployment/sample-app2-sample-app
```

### Expected Timeline

- **Git Push**: Immediate
- **FluxCD Detection**: 1-2 minutes
- **Pod Restart**: 2-3 minutes
- **Application Ready**: 3-5 minutes total

### Best Practices

1. **Always Version Your Changes**: Increment the chart version for any changes
2. **Use Descriptive Commit Messages**: Include what changed and why
3. **Test Locally First**: Use `helm template` to validate your changes
4. **Monitor the Pipeline**: Watch logs and status during deployment
5. **Rollback Strategy**: Keep previous versions for quick rollback if needed

### Common Issues and Solutions

#### Issue: Changes Not Reflected
**Cause**: Chart version not updated
**Solution**: Increment chart version and update HelmRelease

#### Issue: Pod Not Updating
**Cause**: FluxCD not detecting changes
**Solution**: Force reconciliation or check GitRepository status

#### Issue: Template Errors
**Cause**: Invalid Helm template syntax
**Solution**: Use `helm template` to validate before pushing

## Demo Script

See `DEMO_SCRIPT.md` for a complete demonstration walkthrough.

## Documentation

- `AUTOMATION_SUMMARY.md`: Automation features and capabilities
- `QUICK_REFERENCE.md`: Essential commands and shortcuts
- `GITHUB_SETUP.md`: GitHub repository setup instructions

## Repository URLs

- **Main Repository**: https://github.com/paraskanwarit/fluxcd-gitops
- **Helm Chart**: https://github.com/paraskanwarit/sample-app-helm-chart
- **FluxCD Delivery**: https://github.com/paraskanwarit/flux-app-delivery

## Production Considerations

- Enable RBAC and network policies
- Configure monitoring and alerting
- Implement backup and disaster recovery
- Use secrets management for sensitive data
- Set up proper CI/CD pipelines for testing

---