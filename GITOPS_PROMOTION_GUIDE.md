# GitOps Promotion Guide

A step-by-step guide for promoting changes through your GitOps pipeline.

## Quick Start - GitOps Promotion

### Prerequisites
- You have made changes to your application files
- You have access to both repositories
- kubectl is configured to access your GKE cluster

### Step-by-Step Process

#### 1. Update Chart Version
```bash
# Navigate to Helm chart repository
cd sample-app-helm-chart

# Edit the chart version
# File: charts/sample-app/Chart.yaml
# Change: version: 0.1.1 → version: 0.1.2
```

#### 2. Update HelmRelease Version
```bash
# Navigate to delivery repository
cd ../flux-app-delivery

# Edit the HelmRelease version
# File: helmrelease/sample-app-helmrelease.yaml
# Change: version: "0.1.1" → version: "0.1.2"
```

#### 3. Commit and Push Changes
```bash
# Commit Helm chart changes
cd ../sample-app-helm-chart
git add .
git commit -m "Update application - version 0.1.2"
git push origin main

# Commit delivery changes
cd ../flux-app-delivery
git add .
git commit -m "Update HelmRelease to version 0.1.2"
git push origin main
```

#### 4. Monitor Deployment
```bash
# Check GitRepository status
kubectl get gitrepository -n flux-system sample-app-helm-chart -o jsonpath='{.status.artifact.revision}'

# Watch pod updates
kubectl get pods -n sample-app -w

# Check HelmRelease status
kubectl get helmrelease -n sample-app sample-app2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
```

#### 5. Verify Changes
```bash
# Test the application
kubectl port-forward -n sample-app svc/sample-app2-sample-app 8080:80 &
curl http://localhost:8080
```

## One-Liner Status Check
```bash
echo "=== GitOps Status ===" && \
echo "GitRepository: $(kubectl get gitrepository -n flux-system sample-app-helm-chart -o jsonpath='{.status.artifact.revision}')" && \
echo "HelmRelease: $(kubectl get helmrelease -n sample-app sample-app2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" && \
echo "Pods: $(kubectl get pods -n sample-app --no-headers | wc -l) running"
```

## Troubleshooting

### Issue: Changes Not Detected
```bash
# Force reconciliation
kubectl patch helmrelease -n sample-app sample-app2 --type='merge' -p='{"metadata":{"annotations":{"fluxcd.io/reconcile":"true"}}}'
```

### Issue: Template Errors
```bash
# Check FluxCD logs
kubectl logs -n flux-system deployment/helm-controller --tail=20

# Validate Helm template locally
cd sample-app-helm-chart
helm template charts/sample-app
```

### Issue: Pod Not Updating
```bash
# Check if new version is detected
kubectl get helmrelease -n sample-app sample-app2 -o yaml | grep -A 5 -B 5 "version"

# Delete and recreate (nuclear option)
kubectl delete helmrelease -n sample-app sample-app2
kubectl apply -f flux-app-delivery/helmrelease/sample-app-helmrelease.yaml
```

## Expected Timeline
- **Git Push**: Immediate
- **FluxCD Detection**: 1-2 minutes
- **Pod Restart**: 2-3 minutes
- **Application Ready**: 3-5 minutes total

## Best Practices

1. **Always Version Changes**: Increment chart version for any change
2. **Test Locally**: Use `helm template` to validate before pushing
3. **Monitor Pipeline**: Watch logs during deployment
4. **Use Descriptive Messages**: Include what changed in commit messages
5. **Keep Previous Versions**: For quick rollback if needed

## Common Commands Reference

### Status Commands
```bash
# Check all GitOps resources
kubectl get gitrepository,helmchart,helmrelease -A

# Check specific resource
kubectl get helmrelease -n sample-app sample-app2 -o yaml

# Check pod status
kubectl get pods -n sample-app
```

### Log Commands
```bash
# FluxCD controller logs
kubectl logs -n flux-system deployment/helm-controller -f

# Application logs
kubectl logs -n sample-app deployment/sample-app2-sample-app

# All events
kubectl get events -n sample-app --sort-by='.lastTimestamp'
```

### Testing Commands
```bash
# Port forward to test
kubectl port-forward -n sample-app svc/sample-app2-sample-app 8080:80 &

# Test application
curl http://localhost:8080

# Check ConfigMap
kubectl get configmap -n sample-app sample-app-html -o yaml
```

## Version Management

### Chart Versioning Strategy
- **Patch**: 0.1.1 → 0.1.2 (bug fixes, content updates)
- **Minor**: 0.1.2 → 0.2.0 (new features)
- **Major**: 0.2.0 → 1.0.0 (breaking changes)

### Example Version Bump
```bash
# For content changes (like updating demo page)
# Chart.yaml: version: 0.1.1 → version: 0.1.2
# HelmRelease: version: "0.1.1" → version: "0.1.2"

# For new features
# Chart.yaml: version: 0.1.2 → version: 0.2.0
# HelmRelease: version: "0.1.2" → version: "0.2.0"
```

## Rollback Process

### Quick Rollback
```bash
# Revert to previous version
# 1. Change version back in both files
# 2. Commit and push changes
# 3. Monitor deployment

# Or force rollback
kubectl patch helmrelease -n sample-app sample-app2 --type='merge' -p='{"spec":{"chart":{"spec":{"version":"0.1.1"}}}}'
```

--