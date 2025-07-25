# Flux App Delivery

This repository contains FluxCD manifests to deploy the sample NGINX app (from the sample-app-helm-chart repo) into your GKE cluster using GitOps.

## Structure
- `namespaces/`: Namespace manifest for the app.
- `helmrelease/`: HelmRelease and GitRepository manifests for the app Helm chart.
- `kustomization.yaml`: Kustomize entrypoint for FluxCD.

## Usage

1. Ensure FluxCD is installed and configured on your GKE cluster.
2. Point your FluxCD installation to this repo (e.g., via a `GitRepository` and `Kustomization` in `flux-system`).
3. FluxCD will create the namespace, fetch the Helm chart from the sample-app-helm-chart repo, and deploy the app.

## Customization
- Edit the HelmRelease values to customize the app deployment. 