terraform {
  required_providers {
        kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    aws = {
      version = ">= 4.1.0"
    }
  }
}

locals {
  key = var.username
}

data aws_caller_identity "current" {}

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
}

resource "kubectl_manifest" "pvc" {
  yaml_body = <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "${local.key}-efs"
  namespace: ${local.key}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
YAML
}

data aws_route53_zone "kubeflow_zone" {
  name = "platform.${var.domain_name}"
}

data aws_cognito_user_pools "pool" {
  name = "${data.aws_route53_zone.kubeflow_zone.name}-user-pool"
}

resource "aws_cognito_user" "users" {
  user_pool_id = tolist(data.aws_cognito_user_pools.pool.ids)[0]
  username = local.key
  attributes = {
    email = "${local.key}@hyperfine.io"
    email_verified = true
  }
  temporary_password = "Password1!"
}
