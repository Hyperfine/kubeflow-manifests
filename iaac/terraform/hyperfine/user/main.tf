terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    aws = {
      version = ">= 3.71"
    }
  }
}

resource "kubernetes_namespace_v1" "ns" {
  metadata {
    name = split("@", var.email)[0]

    annotations = {
      owner: var.email
    }
  }
}

locals {
  name = kubernetes_namespace_v1.ns.metadata[0].name
  email = var.email
  sa_name = "${local.name}-sa"
}

resource "kubectl_manifest" "config" {
  yaml_body = <<YAML
apiVersion: v1
data:
  profile-name: ${local.name}
  user: ${local.email}
kind: ConfigMap
metadata:
  name: default-install-config-${local.name}
YAML
}

resource "kubectl_manifest" "profile" {
  yaml_body = <<YAML
apiVersion: kubeflow.org/v1beta1
kind: Profile
metadata:
  name: ${local.name}
spec:
  owner:
    kind: User
    name: ${local.email}
YAML
}

