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

    labels = {
      "app.kubernetes.io/part-of"                      = "kubeflow-profile"
      "katib.kubeflow.org/metrics-collector-injection" = "enabled"
      "pipelines.kubeflow.org/enabled"                 = "true"
      "serving.kubeflow.org/inferenceservice"          = "enabled"
    }

    annotations = {
      owner: var.email
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels["app.kubernetes.io/part-of"],
      metadata[0].labels["katib.kubeflow.org/metrics-collector-injection"],
      metadata[0].labels["pipelines.kubeflow.org/enabled"],
      metadata[0].labels["serving.kubeflow.org/inferenceservice"]
    ]
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

