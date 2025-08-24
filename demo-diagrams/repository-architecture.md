# GitOps Repository Architecture Diagram

```mermaid
graph TB
    subgraph "Infrastructure Repository"
        A[gke-gitops-infra]
        A1[terraform-module/]
        A2[environment/non-prod/dev/]
        A3[flux-bootstrap/]
        
        A --> A1
        A --> A2
        A --> A3
        
        A1 --> A1a[GKE Module<br/>Terraform Code]
        A2 --> A2a[main.tf<br/>GKE Cluster Config]
        A3 --> A3a[main.tf<br/>Flux Bootstrap Config]
    end
    
    subgraph "Application Helm Chart Repository"
        B[sample-app-helm-chart<br/>github.com/paraskanwarit/sample-app-helm-chart]
        B1[charts/sample-app/]
        B2[values.yaml]
        
        B --> B1
        B --> B2
        
        B1 --> B1a[Chart.yaml<br/>templates/<br/>Helm Chart Files]
        B2 --> B2a[Default App Configuration<br/>Image, Replicas, etc.]
    end
    
    subgraph "GitOps Configuration Repository"
        C[flux-app-delivery]
        C1[helmrelease/]
        C2[namespaces/]
        
        C --> C1
        C --> C2
        
        C1 --> C1a[sample-app-helmrelease.yaml<br/>HelmRelease Object]
        C1 --> C1b[sample-app-helmrepository.yaml<br/>GitRepository Object]
        C2 --> C2a[sample-app-namespace.yaml<br/>Namespace Definition]
    end
    
    subgraph "GKE Cluster"
        D[Kubernetes Cluster]
        D1[Flux Controllers]
        D2[Sample App Deployment]
        
        D --> D1
        D --> D2
    end
    
    %% Relationships
    A2a -.->|provisions| D
    A3a -.->|installs| D1
    C1b -.->|references| B
    C1a -.->|uses chart from| B1a
    C1a -.->|references| C1b
    D1 -.->|monitors| C
    D1 -.->|pulls from| B
    D1 -.->|deploys| D2
    
    %% Styling
    classDef infraRepo fill:#e1f5fe
    classDef appRepo fill:#f3e5f5
    classDef gitopsRepo fill:#e8f5e8
    classDef cluster fill:#fff3e0
    
    class A,A1,A2,A3,A1a,A2a,A3a infraRepo
    class B,B1,B2,B1a,B2a appRepo
    class C,C1,C2,C1a,C1b,C2a gitopsRepo
    class D,D1,D2 cluster
```

## Repository Responsibilities

### 🏗️ Infrastructure Repository (gke-gitops-infra)
- **Purpose**: Infrastructure as Code
- **Contains**: Terraform modules, GKE cluster configuration, Flux bootstrap
- **Owner**: Platform/DevOps Team

### 📦 Application Helm Chart Repository (sample-app-helm-chart)
- **Purpose**: Application packaging and templating
- **Contains**: Helm charts, default values, application templates
- **Owner**: Development Team

### 🔄 GitOps Configuration Repository (flux-app-delivery)
- **Purpose**: Deployment configuration and GitOps manifests
- **Contains**: HelmRelease, GitRepository, Namespace definitions
- **Owner**: DevOps/SRE Team

### ☸️ GKE Cluster
- **Purpose**: Runtime environment
- **Contains**: Flux controllers, deployed applications
- **Managed by**: Flux CD Controllers