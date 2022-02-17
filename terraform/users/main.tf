terraform {
  required_providers {
        kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

locals {
  key = var.username
}
data aws_caller_identity "current" {}

data "kubectl_file_documents" "user" {
  content = <<YAML
apiVersion: v1
data:
  profile-name: ${local.key}
  user: "${local.key}@hyperfine.io"
kind: ConfigMap
metadata:
  name: default-install-config-${local.key}
---
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

resource "kubectl_manifest" "user" {
    for_each = data.kubectl_file_documents.user.manifests
    yaml_body = each.value
}

data aws_route53_zone "kubeflow_zone" {
  name = "platform.${var.domain_name}"
}

data aws_cognito_user_pools "pool" {
  name = "${data.aws_route53_zone.kubeflow_zone.name}-user-pool"
}

locals {
  pool_id = one(data.aws_cognito_user_pools.pool.ids)
}

resource "null_resource" "cognito_user" {
  # https://github.com/hashicorp/terraform-provider-aws/pull/19919 switch to whenever merged
  triggers = {
    user_pool_id = data.aws_cognito_user_pools.pool.id
    username = local.key
  }

  provisioner "local-exec" {
    command = <<EOT
    aws cognito-idp admin-create-user \
      --user-pool-id ${local.pool_id} \
      --username ${local.key} \
      --temporary-password Password1! \
      --user-attributes Name=email,Value="${local.key}@hyperfine.io" \
    || \
    true
    EOT
  }
}
