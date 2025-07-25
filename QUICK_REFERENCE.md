# ⚡ GitOps Demo Quick Reference

## 🚀 One-Command Setup
```bash
./scripts/complete-setup.sh
```

## 📊 Current Status Commands

### Infrastructure
```bash
# GKE Cluster
kubectl get nodes
kubectl get deployment -n flux-system

# FluxCD Version
kubectl get deployment -n flux-system helm-controller -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Application
```bash
# Application Status
kubectl get pods -n sample-app
kubectl get svc -n sample-app
kubectl get helmrelease -n sample-app

# Application Logs
kubectl logs -n sample-app -l app=sample-app
```

### GitOps Resources
```bash
# FluxCD Resources
kubectl get gitrepository -A
kubectl get helmchart -A
kubectl get helmrelease -A

# FluxCD Logs
kubectl logs -n flux-system deployment/helm-controller --tail=20
kubectl logs -n flux-system deployment/source-controller --tail=20
```

## 🧪 Testing Commands

### Application Connectivity
```bash
# Port forward and test
kubectl port-forward -n sample-app svc/sample-app2-sample-app 8080:80 &
curl http://localhost:8080
```

### Health Checks
```bash
# Check all components
kubectl get all -n sample-app
kubectl get all -n flux-system
```

## 🎭 Demo Commands

### Show Architecture
```bash
# Display flow diagram
cat README.md | grep -A 20 "## 🏗️ Architecture"
```

### Show GitOps Flow
```bash
# Show the 3 repositories
echo "1. Infrastructure (Terraform) - gke-gitops-infra"
echo "2. Application Chart (Helm) - sample-app-helm-chart"
echo "3. Delivery (FluxCD) - flux-app-delivery"

# Show GitOps resources
kubectl get gitrepository -A
kubectl get helmchart -A
kubectl get helmrelease -A
```

### Live Change Demo
```bash
# Show current deployment
kubectl get deployment -n sample-app sample-app2-sample-app

# Watch for changes
kubectl get pods -n sample-app -w

# Show events
kubectl get events -n sample-app --sort-by='.lastTimestamp' | tail -10
```

## 🔧 Troubleshooting Commands

### FluxCD Issues
```bash
# Force reconciliation
kubectl patch helmrelease -n sample-app sample-app2 \
  --type='merge' -p='{"metadata":{"annotations":{"fluxcd.io/reconcile":"true"}}}'

# Check FluxCD status
kubectl get deployment -n flux-system
kubectl logs -n flux-system deployment/helm-controller
```

### Application Issues
```bash
# Check application status
kubectl describe pod -n sample-app -l app=sample-app
kubectl logs -n sample-app -l app=sample-app

# Restart application
kubectl rollout restart deployment -n sample-app sample-app2-sample-app
```

### Authentication Issues
```bash
# Refresh GCP credentials
gcloud auth print-access-token
gcloud container clusters get-credentials gk3-dev-gke-autopilot --region=us-central1
```

## 📋 Key Information

### Current Configuration
- **GKE Cluster**: `gk3-dev-gke-autopilot`
- **Region**: `us-central1`
- **Project**: `extreme-gecko-466211-t1`
- **FluxCD Version**: `v2.12.2`
- **Application**: NGINX sample app

### GitHub Repositories
- **Helm Chart**: `https://github.com/paraskanwarit/sample-app-helm-chart`
- **Delivery**: `https://github.com/paraskanwarit/flux-app-delivery`

### Access URLs
- **GKE Console**: `https://console.cloud.google.com/kubernetes/clusters/details/us-central1/gk3-dev-gke-autopilot?project=extreme-gecko-466211-t1`
- **Application**: `http://localhost:8080` (via port-forward)

## 🎯 Demo Highlights

### What to Show
1. **Infrastructure**: GKE cluster with FluxCD
2. **GitOps Flow**: 3-repository pattern
3. **Application**: Real NGINX serving traffic
4. **Automation**: Zero manual intervention
5. **Production Ready**: Enterprise-grade setup

### Key Benefits
- ✅ **Zero Manual Intervention**: Fully automated
- ✅ **Git as Source of Truth**: All changes tracked
- ✅ **Production Ready**: Enterprise security
- ✅ **Real Application**: Serving actual traffic
- ✅ **Scalable**: Easy to replicate

## 🚨 Emergency Commands

### Reset Everything
```bash
# Delete application
kubectl delete namespace sample-app

# Recreate application
kubectl apply -f flux-app-delivery/namespaces/sample-app-namespace.yaml
kubectl apply -f flux-app-delivery/helmrelease/sample-app-helmrepository.yaml
kubectl apply -f flux-app-delivery/helmrelease/sample-app-helmrelease.yaml
```

### Check Everything
```bash
# Comprehensive health check
kubectl get nodes && \
kubectl get deployment -n flux-system && \
kubectl get pods -n sample-app && \
kubectl get helmrelease -A && \
echo "✅ All systems operational"
```

---

**🎉 Your GitOps demo is ready to impress!**

This quick reference contains all the essential commands and information you need for a successful GitOps demonstration. 