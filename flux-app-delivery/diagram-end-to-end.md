# End-to-End GitOps Flow

```mermaid
flowchart TD
    subgraph "4. End-to-End GitOps Flow"
        A["Terraform Infra"] --> B["GKE Cluster"]
        B --> C["FluxCD Installed"]
        C --> D["Flux Watches Delivery Repo"]
        D --> E["HelmRelease Points to Helm Chart Repo"]
        E --> F["App Deployed in GKE"]
    end
```

**Explanation:**
- Infrastructure is provisioned with Terraform.
- FluxCD is installed and configured to watch the delivery repo.
- HelmRelease manifests in the delivery repo point to the Helm chart repo.
- The app is automatically deployed to GKE via GitOps. 