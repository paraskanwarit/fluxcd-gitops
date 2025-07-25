terraform {
  required_version = ">= 1.3.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.1"
    }
  }
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = var.gke_token
}

provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    token                  = var.gke_token
  }
}

resource "helm_release" "flux" {
  name       = "flux"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  version    = var.flux_version
  namespace  = "flux-system"
  create_namespace = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "watchAllNamespaces"
      value = "true"
    },
    {
      name  = "networkPolicy.create"
      value = "true"
    },
    {
      name  = "metrics.enabled"
      value = "true"
    },
    {
      name  = "events.enabled"
      value = "true"
    }
  ]
} 