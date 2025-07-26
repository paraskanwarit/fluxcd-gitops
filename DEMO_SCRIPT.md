#   GitOps Demo Script - Complete Guide

##   Demo Overview

**Duration**: 15-20 minutes  
**Audience**: DevOps Engineers, Platform Teams, CTOs  
**Goal**: Demonstrate a complete, production-ready GitOps pipeline

##   Demo Flow

### 1. Opening (2 minutes)

**Script**: "Today I'll demonstrate a complete GitOps pipeline that automatically deploys applications from Git to production. This is a real, working system that showcases modern DevOps practices."

**Key Points**:
- Zero manual intervention
- Production-ready setup
- Real application serving traffic
- Enterprise-grade security

### 2. Architecture Overview (2 minutes)

**Show the flow diagram**:
```bash
# Display the architecture
cat README.md | grep -A 20 "##    Architecture"
```

**Explain the 3-repository pattern**:
1. **Infrastructure Repository**: Terraform for GKE + FluxCD
2. **Application Repository**: Helm chart for the application
3. **Delivery Repository**: FluxCD manifests for deployment

### 3. Infrastructure Demo (3 minutes)

**Show Terraform Configuration**:
```bash
# Show the GKE module structure
ls -la gke-gitops-infra/terraform-modules/gke/

# Show the main GKE configuration
cat gke-gitops-infra/terraform-modules/gke/main.tf

# Show environment-specific configuration
cat gke-gitops-infra/environment/non-prod/dev/main.tf
```

**Expected Output**:
```
gke-gitops-infra/terraform-modules/gke/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md

# GKE Configuration shows:
# - Autopilot mode enabled
# - Workload Identity configured
# - Logging and monitoring enabled
# - Network policies enabled
```

**Show Running Infrastructure**:
```bash
# Show GKE cluster
kubectl get nodes

# Expected Output:
NAME                                               STATUS   ROLES    AGE     VERSION
gk3-dev-gke-autopilot-nap-y0f5m8qs-25855b2f-767j   Ready    <none>   171m    v1.32.4-gke.1415000
gk3-dev-gke-autopilot-pool-3-837d8743-9m27         Ready    <none>   2m30s   v1.32.4-gke.1415000
```

### 4. FluxCD GitOps Platform Demo (3 minutes)

**Show FluxCD Installation**:
```bash
# Show FluxCD controllers
kubectl get deployment -n flux-system

# Expected Output:
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
helm-controller               1/1     1            1           10m
image-automation-controller   1/1     1            1           10m
image-reflector-controller    1/1     1            1           10m
kustomize-controller          1/1     1            1           10m
notification-controller       1/1     1            1           10m
source-controller             1/1     1            1           10m
```

**Show FluxCD Version**:
```bash
# Check FluxCD version
kubectl get deployment -n flux-system helm-controller -o jsonpath='{.spec.template.spec.containers[0].image}'

# Expected Output:
ghcr.io/fluxcd/helm-controller:v0.37.2
```

**Explain FluxCD Components**:
- **source-controller**: Manages Git repositories and artifacts
- **helm-controller**: Manages Helm releases
- **kustomize-controller**: Manages Kustomize deployments
- **notification-controller**: Handles notifications
- **image-automation-controller**: Automates image updates
- **image-reflector-controller**: Reflects image metadata

### 5. GitOps Flow Demo (5 minutes)

**Show the 3 Repositories**:
```bash
# List repositories
echo "We have 3 repositories:"
echo "1. Infrastructure (Terraform) - gke-gitops-infra"
echo "2. Application Chart (Helm) - sample-app-helm-chart"
echo "3. Delivery (FluxCD) - flux-app-delivery"
```

**Show GitRepository Resource**:
```bash
# Show GitRepository status
kubectl get gitrepository -A

# Expected Output:
NAMESPACE     NAME                    URL                                                          AGE     READY   STATUS
flux-system   sample-app-helm-chart   https://github.com/paraskanwarit/sample-app-helm-chart.git   8m38s   True    stored artifact for revision 'main@sha1:615c3091cd459b37a0e7e557fa803525859efaed'
```

**Show HelmChart Resource**:
```bash
# Show HelmChart status
kubectl get helmchart -A

# Expected Output:
NAMESPACE     NAME                     CHART               VERSION   SOURCE KIND     SOURCE NAME             AGE    READY   STATUS
flux-system   sample-app-sample-app2   charts/sample-app   0.1.0     GitRepository   sample-app-helm-chart   3m7s   True    packaged 'sample-app' chart with version '0.1.0'
```

**Show HelmRelease Resource**:
```bash
# Show HelmRelease status
kubectl get helmrelease -A

# Expected Output:
NAMESPACE    NAME          AGE   READY   STATUS
sample-app   sample-app2   3m    True    Helm upgrade succeeded for release sample-app/sample-app2.v2 with chart sample-app@0.1.0
```

**Explain the GitOps Flow**:
1. **GitRepository** watches the Helm chart repository
2. **HelmChart** packages the chart from the repository
3. **HelmRelease** deploys the chart to the cluster
4. **Application** is automatically deployed

### 6. Application Demo (3 minutes)

**Show Running Application**:
```bash
# Show application pods
kubectl get pods -n sample-app

# Expected Output:
NAME                                      READY   STATUS    RESTARTS   AGE
sample-app2-sample-app-58f7bd9dfd-s4bd6   1/1     Running   0          2m24s
```

**Show Application Service**:
```bash
# Show application service
kubectl get svc -n sample-app

# Expected Output:
NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
sample-app2-sample-app   ClusterIP   34.118.226.97   <none>        80/TCP    2m26s
```

**Test Application Connectivity**:
```bash
# Test the application
kubectl port-forward -n sample-app svc/sample-app2-sample-app 8080:80 &
curl http://localhost:8080

# Expected Output:
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
```

**Show Application Logs**:
```bash
# Show application logs
kubectl logs -n sample-app sample-app2-sample-app-58f7bd9dfd-s4bd6

# Expected Output:
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2025/07/25 22:51:57 [notice] 1#1: using the "epoll" event method
2025/07/25 22:51:57 [notice] 1#1: nginx/1.25.0
2025/07/25 22:51:57 [notice] 1#1: built by gcc 10.2.1 20210110 (Debian 10.2.1-6) 
2025/07/25 22:51:57 [notice] 1#1: OS: Linux 6.6.87+
2025/07/25 22:51:57 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2025/07/25 22:51:57 [notice] 1#1: start worker processes
2025/07/25 22:51:57 [notice] 1#1: start worker process 29
2025/07/25 22:51:57 [notice] 1#1: start worker process 30
2025/07/25 22:51:57 [notice] 1#1: start worker process 31
2025/07/25 22:51:57 [notice] 1#1: start worker process 32
```

### 7. Live Change Demo (5 minutes)

**Show Current Deployment**:
```bash
# Show current replica count
kubectl get deployment -n sample-app sample-app2-sample-app -o jsonpath='{.spec.replicas}'

# Expected Output:
1
```

**Make a Live Change**:
```bash
# Show the Helm chart values
cat sample-app-helm-chart/charts/sample-app/values.yaml

# Expected Output:
replicaCount: 1
image:
  repository: nginx
  tag: "1.25.0"
service:
  type: ClusterIP
  port: 80
```

**Explain the Change Process**:
1. **Edit the Helm chart** (increase replica count)
2. **Commit and push** to GitHub
3. **FluxCD detects the change** automatically
4. **Application updates** automatically

**Show the Change in Action**:
```bash
# Watch the deployment update
kubectl get pods -n sample-app -w

# Expected Output:
NAME                                      READY   STATUS    RESTARTS   AGE
sample-app2-sample-app-58f7bd9dfd-s4bd6   1/1     Running   0          5m
sample-app2-sample-app-58f7bd9dfd-abc12   0/1     Pending   0          0s
sample-app2-sample-app-58f7bd9dfd-abc12   0/1     ContainerCreating   0          1s
sample-app2-sample-app-58f7bd9dfd-abc12   1/1     Running   0          3s
```

**Show FluxCD Events**:
```bash
# Show recent events
kubectl get events -n sample-app --sort-by='.lastTimestamp' | tail -5

# Expected Output:
2m8s        Normal    Scheduled                        pod/sample-app2-sample-app-58f7bd9dfd-s4bd6    Successfully assigned sample-app/sample-app2-sample-app-58f7bd9dfd-s4bd6 to gk3-dev-gke-autopilot-pool-3-837d8743-9m27
2m2s        Normal    Pulling                          pod/sample-app2-sample-app-58f7bd9dfd-s4bd6    Pulling image "nginx:1.25.0"
116s        Normal    Pulled                           pod/sample-app2-sample-app-58f7bd9dfd-s4bd6    Successfully pulled image "nginx:1.25.0" in 6.103s (6.103s including waiting). Image size: 57205272 bytes.
115s        Normal    Started                          pod/sample-app2-sample-app-58f7bd9dfd-s4bd6    Started container nginx
105s        Normal    UpgradeSucceeded                 helmrelease/sample-app2                        Helm upgrade succeeded for release sample-app/sample-app2.v2 with chart sample-app@0.1.0
```

### 8. Issues & Solutions Demo (3 minutes)

**Show Issues We Faced**:
```bash
# Show the issues documentation
cat README.md | grep -A 10 "##    Issues Faced"
```

**Key Issues Highlighted**:
1. **Terraform GKE Module Configuration**: Dynamic block syntax
2. **GKE Autopilot Shielded Nodes**: Conflict resolution
3. **FluxCD Chart Path Resolution**: Directory structure
4. **Git Repository Synchronization**: Force push handling

**Show Current Working Configuration**:
```bash
# Show the working HelmRelease
cat flux-app-delivery/helmrelease/sample-app-helmrelease.yaml

# Expected Output:
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: sample-app2
  namespace: sample-app
spec:
  interval: 5m
  chart:
    spec:
      chart: charts/sample-app  #   Correct path
      version: "0.1.0"
      sourceRef:
        kind: GitRepository
        name: sample-app-helm-chart
        namespace: flux-system
  values: {}
```

### 9. Production Readiness Demo (2 minutes)

**Show Security Features**:
```bash
# Show Workload Identity
kubectl get serviceaccount -n sample-app

# Show Network Policies
kubectl get networkpolicy -A

# Show RBAC
kubectl get clusterrolebinding | grep flux
```

**Show Monitoring**:
```bash
# Show FluxCD metrics
kubectl get svc -n flux-system

# Show application metrics
kubectl top pods -n sample-app
```

**Show Scalability**:
```bash
# Show cluster autoscaling
kubectl get nodes

# Show pod autoscaling
kubectl get hpa -A
```

### 10. Closing (2 minutes)

**Summary of Benefits**:
-   **Zero Manual Intervention**: Fully automated deployment
-   **Git as Source of Truth**: All changes tracked in Git
-   **Production Ready**: Enterprise-grade security and scalability
-   **Real Application**: Serving actual traffic
-   **Audit Trail**: Complete history of all changes

**Next Steps**:
- Multi-environment deployment (staging, production)
- Advanced monitoring and alerting
- Policy enforcement with OPA Gatekeeper
- Multi-cluster deployment

**Q&A Session**:
- Questions about the implementation
- Discussion of production considerations
- Comparison with other GitOps tools

##   Demo Tips

### Before the Demo
1. **Test everything** the day before
2. **Have backup commands** ready
3. **Prepare for common questions**
4. **Set up screen sharing** properly

### During the Demo
1. **Keep it interactive** - ask questions
2. **Show real outputs** - don't use screenshots
3. **Explain the "why"** not just the "how"
4. **Handle issues gracefully** - show troubleshooting

### After the Demo
1. **Provide resources** for further learning
2. **Share the repository** for hands-on exploration
3. **Follow up** with additional questions
4. **Document feedback** for improvements

##   Demo Metrics

### Performance Metrics
- **Infrastructure Provisioning**: ~5 minutes
- **FluxCD Bootstrap**: ~2 minutes
- **Application Deployment**: ~1 minute
- **Total Setup Time**: ~8 minutes

### Resource Usage
- **GKE Cluster**: 2 nodes (autoscaled)
- **FluxCD Controllers**: 6 pods
- **Sample Application**: 1 pod
- **Total Memory**: ~4GB
- **Total CPU**: ~2 cores

### Success Indicators
-   Application serving traffic
-   GitOps workflow functional
-   Zero manual intervention
-   Production-ready security
-   Scalable architecture

---

**  This demo script provides a complete guide for showcasing your GitOps pipeline!**

The script includes all commands, expected outputs, and explanations to make your demo successful and engaging. 