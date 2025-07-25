# Flux App Delivery Repo Flow

```mermaid
flowchart TD
    subgraph "3. Flux App Delivery Repo"
        G["FluxCD GitRepository Manifest"] --> H["FluxCD HelmRelease Manifest"]
        H --> I["Deploys Helm Chart to GKE Namespace"]
    end
```

**Explanation:**
- FluxCD watches the delivery repo for changes.
- The GitRepository manifest points to the Helm chart repo.
- The HelmRelease manifest deploys the app to the GKE cluster. 