terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
        kustomization = {
      source  = "kbst/kustomization"
      version = "0.7.2"
    }
  }
}