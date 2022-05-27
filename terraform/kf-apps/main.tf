terraform {
  required_providers {
        kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
        kustomization = {
      source  = "kbst/kustomization"
      version = "0.8.1"
    }
  }
}