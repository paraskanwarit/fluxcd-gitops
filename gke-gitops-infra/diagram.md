# End-to-End GitOps Flow Diagram

This diagram illustrates the flow from infrastructure provisioning to application deployment using GitOps with GKE, FluxCD, and Helm.

```mermaid
flowchart TD
    subgraph "1. Infra Repo"
        A["Terraform GKE Module"] --> B["Dev Environment Terraform"]
    end
    B --> C["GKE Autopilot Cluster"]
    C --> D["FluxCD Bootstrapped (via Terraform)"]
    subgraph "2. App Helm Chart Repo"
        E["Helm Chart: Sample App"]
    end
    subgraph "3. Flux App Delivery Repo"
        F["FluxCD HelmRelease YAMLs"]
    end
    D --> F
    F --> E
    E --> G["App Deployed in GKE Namespace"]
```

**Explanation:**
- Terraform provisions the GKE cluster and installs FluxCD.
- FluxCD is configured to watch the Flux App Delivery repo.
- The Flux App Delivery repo contains HelmRelease manifests that reference the App Helm Chart repo.
- FluxCD deploys the app into the cluster, in a new namespace. 