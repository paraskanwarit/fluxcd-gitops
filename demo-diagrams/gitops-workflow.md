# GitOps Workflow Diagrams

## 1. FluxCD GitOps Architecture Overview

```mermaid
graph TB
    subgraph "Developer Workflow"
        DEV[Developer] --> |1. Push code changes| HELM_REPO[sample-app-helm-chart]
        DEV --> |2. Update deployment config| FLUX_REPO[flux-app-delivery]
    end
    
    subgraph "GitHub Repositories"
        HELM_REPO --> |Contains| HELM_CHART[Helm Chart<br/>charts/sample-app/]
        FLUX_REPO --> |Contains| FLUX_CONFIG[FluxCD Configs<br/>sample-app-namespace.yaml<br/>sample-app-helmrelease.yaml<br/>sample-app-source.yaml]
    end
    
    subgraph "GKE Cluster (dev-gke-autopilot)"
        subgraph "flux-system namespace"
            FLUX_CONTROLLERS[FluxCD Controllers<br/>- source-controller<br/>- helm-controller<br/>- kustomize-controller]
        end
        
        subgraph "sample-app namespace"
            NGINX_PODS[NGINX Pods<br/>sample-app2-sample-app-xxx]
            SVC[Service<br/>sample-app2-sample-app]
        end
    end
    
    FLUX_CONTROLLERS --> |3. Watches| FLUX_REPO
    FLUX_CONTROLLERS --> |4. Fetches| HELM_REPO
    FLUX_CONTROLLERS --> |5. Deploys| NGINX_PODS
    FLUX_CONTROLLERS --> |6. Creates| SVC
    
    style DEV fill:#e1f5fe
    style FLUX_CONTROLLERS fill:#f3e5f5
    style NGINX_PODS fill:#e8f5e8
    style HELM_REPO fill:#fff3e0
    style FLUX_REPO fill:#fff3e0
```

## 2. Repository Interconnection Diagram

```mermaid
graph LR
    subgraph "GitHub - paraskanwarit"
        subgraph "sample-app-helm-chart"
            CHART_DIR[charts/sample-app/]
            CHART_YAML[Chart.yaml<br/>version: 0.1.2]
            VALUES_YAML[values.yaml<br/>image: nginx:latest<br/>replicas: 2]
            TEMPLATES[templates/<br/>deployment.yaml<br/>service.yaml]
        end
        
        subgraph "flux-app-delivery"
            NAMESPACE_YAML[sample-app-namespace.yaml]
            SOURCE_YAML[sample-app-source.yaml<br/>↳ Points to helm chart repo]
            HELMRELEASE_YAML[sample-app-helmrelease.yaml<br/>↳ References source & chart]
        end
        
        subgraph "fluxcd-gitops"
            SETUP_SCRIPT[scripts/complete-setup.sh]
            TERRAFORM[gke-gitops-infra/]
            DOCS[README.md<br/>demo-diagrams/]
        end
    end
    
    SOURCE_YAML -.->|references| CHART_DIR
    HELMRELEASE_YAML -.->|uses chart from| SOURCE_YAML
    SETUP_SCRIPT -.->|creates GitRepository pointing to| flux-app-delivery
    SETUP_SCRIPT -.->|creates Kustomization watching| flux-app-delivery
    
    style CHART_DIR fill:#e3f2fd
    style SOURCE_YAML fill:#f1f8e9
    style HELMRELEASE_YAML fill:#f1f8e9
    style SETUP_SCRIPT fill:#fce4ec
```

## 3. Change Propagation Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant HelmRepo as sample-app-helm-chart
    participant FluxRepo as flux-app-delivery
    participant FluxCD as FluxCD Controllers
    participant K8s as Kubernetes Cluster
    
    Note over Dev,K8s: Scenario: Update NGINX image version
    
    Dev->>HelmRepo: 1. Update values.yaml<br/>image: nginx:1.25
    Dev->>HelmRepo: 2. Bump Chart.yaml<br/>version: 0.1.3
    Dev->>HelmRepo: 3. git push origin main
    
    Note over FluxCD: FluxCD polls every 1 minute
    
    FluxCD->>HelmRepo: 4. Detect new chart version
    FluxCD->>FluxCD: 5. Download & validate chart
    
    FluxCD->>FluxRepo: 6. Check HelmRelease config
    Note over FluxCD: HelmRelease points to chart version 0.1.3
    
    FluxCD->>K8s: 7. Apply Helm upgrade
    K8s->>K8s: 8. Rolling update deployment
    K8s->>K8s: 9. New pods with nginx:1.25
    
    Note over Dev,K8s: ✅ Change automatically deployed!
```

## 4. File Structure & Relationships

```
GitHub Repositories Structure:
├── sample-app-helm-chart/
│   ├── charts/sample-app/
│   │   ├── Chart.yaml ────────────┐
│   │   ├── values.yaml           │
│   │   └── templates/            │
│   │       ├── deployment.yaml   │
│   │       └── service.yaml      │
│   └── README.md                 │
│                                 │
├── flux-app-delivery/          │
│   ├── sample-app-namespace.yaml │
│   ├── sample-app-source.yaml ───┼─── references chart repo
│   ├── sample-app-helmrelease.yaml ──┘
│   └── README.md
│
└── fluxcd-gitops/
    ├── scripts/
    │   ├── complete-setup.sh ─────── creates GitRepo & Kustomization
    │   └── complete-destroy.sh
    ├── gke-gitops-infra/
    │   └── flux-bootstrap/ ───────── Terraform for FluxCD
    ├── demo-diagrams/ ────────────── This documentation
    └── README.md ─────────────────── Main documentation
```

## 5. FluxCD Resource Relationships in Cluster

```mermaid
graph TD
    subgraph "flux-system namespace"
        GR[GitRepository<br/>flux-app-delivery<br/>↳ watches GitHub repo]
        K[Kustomization<br/>flux-app-delivery<br/>↳ applies all YAML files]
        
        GR --> K
    end
    
    subgraph "Resources Created by Kustomization"
        NS[Namespace<br/>sample-app]
        GR2[GitRepository<br/>sample-app-helm-chart<br/>↳ watches chart repo]
        HR[HelmRelease<br/>sample-app2<br/>↳ deploys chart]
        
        K --> NS
        K --> GR2
        K --> HR
    end
    
    subgraph "sample-app namespace"
        DEPLOY[Deployment<br/>sample-app2-sample-app]
        SVC[Service<br/>sample-app2-sample-app]
        PODS[Pods<br/>sample-app2-sample-app-xxx]
        
        HR --> DEPLOY
        HR --> SVC
        DEPLOY --> PODS
    end
    
    style GR fill:#e1f5fe
    style K fill:#e1f5fe
    style GR2 fill:#f3e5f5
    style HR fill:#f3e5f5
    style NS fill:#e8f5e8
    style DEPLOY fill:#e8f5e8
    style SVC fill:#e8f5e8
    style PODS fill:#e8f5e8
```

## Key Concepts for Team Explanation

### GitOps Principles
1. **Declarative**: Everything defined in Git as YAML
2. **Versioned**: All changes tracked in Git history
3. **Immutable**: Infrastructure as code, no manual changes
4. **Pulled**: FluxCD pulls changes, not pushed

### Repository Separation Strategy
- **sample-app-helm-chart**: Contains the application package (Helm chart)
- **flux-app-delivery**: Contains deployment configuration (where/how to deploy)
- **fluxcd-gitops**: Contains infrastructure setup and documentation

### Automatic Deployment Flow
1. Developer pushes code → GitHub
2. FluxCD detects changes (every 1 minute)
3. FluxCD applies changes → Kubernetes
4. Application automatically updates

### Benefits
- **No kubectl needed**: Everything through Git
- **Audit trail**: All changes in Git history
- **Rollback capability**: Git revert = application rollback
- **Security**: No cluster credentials needed for developers