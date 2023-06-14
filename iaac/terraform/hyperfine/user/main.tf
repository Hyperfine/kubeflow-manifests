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

locals {
  key = var.username
  sa_name = "${var.username}-sa"
}

resource "kubectl_manifest" "config" {
        yaml_body = <<YAML
apiVersion: v1
data:
  profile-name: ${local.key}
  user: "${local.key}@hyperfine.io"
kind: ConfigMap
metadata:
  name: default-install-config-${local.key}
YAML
}

resource "kubectl_manifest" "profile" {
    yaml_body = <<YAML
apiVersion: kubeflow.org/v1beta1
kind: Profile
metadata:
  name: ${local.key}
spec:
  owner:
    kind: User
    name: "${local.key}@hyperfine.io"
YAML

  provisioner "local-exec" {
    command = <<EOT
      while ! [ "$(kubectl get ns ${local.key} -o jsonpath='{.status.phase}')" == "Active" ]
        do echo 'Waiting for namespace to come online. CTRL-C to exit.'
        sleep 1
      done"
    EOT
  }
}

