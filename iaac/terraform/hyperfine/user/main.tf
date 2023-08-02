terraform {
  required_providers {
    aws = {
      version = ">= 3.71"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

resource "kubernetes_namespace_v1" "ns" {
  metadata {
    name = replace(split("@", var.email)[0], "_", "")

    labels = {
      "app.kubernetes.io/part-of"                      = "kubeflow-profile"
      "katib.kubeflow.org/metrics-collector-injection" = "enabled"
      "pipelines.kubeflow.org/enabled"                 = "true"
      "serving.kubeflow.org/inferenceservice"          = "enabled"
    }

    annotations = {
      owner : var.email
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
  name    = kubernetes_namespace_v1.ns.metadata[0].name
  email   = var.email
  sa_name = "${local.name}-sa"
}

data "aws_iam_policy_document" "ssm" {
  version = "2012-10-17"

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = var.kms_key_arns
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [for k, v in data.aws_secretsmanager_secret.secrets : v.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = var.s3_bucket_arns
  }
}

resource "aws_iam_policy" "ssm" {
  name   = "${var.eks_cluster_name}-${local.name}-sa-policy"
  policy = data.aws_iam_policy_document.ssm.json
}


module "irsa" {
  source                     = "git::git@github.com:hyperfine/terraform-aws-eks.git//modules/eks-irsa?ref=v0.48.3"
  kubernetes_namespace       = local.name
  kubernetes_service_account = local.sa_name
  irsa_iam_policies          = [aws_iam_policy.ssm.arn]
  eks_cluster_id             = var.eks_cluster_name

  create_kubernetes_namespace         = false
  create_service_account_secret_token = true
}

locals {
  module_sa = reverse(split("/", module.irsa.service_account))[0] # implicit dependency
  fsx       = values(var.fsx_configs)[0]                          # only support one config atm
}

resource "helm_release" "user" {
  chart = "../../charts/hyperfine/user"

  namespace = local.name
  name      = "${local.name}-kf-user"
  version   = var.user_helm_chart_version

  values = [<<YAML
name: ${local.name}
email: ${local.email}
s3SecretName: ${var.s3_secret_name}
rdsSecretName: ${var.rds_secret_name}
sshKeySecretName: ${var.ssh_key_secret_name}
serviceAccountName: ${local.module_sa}
efs:
  storageClassName: ${var.efs_storage_class_name}
  accessPoint: ${var.efs_access_point}
  filesystemId: ${var.efs_filesystem_id}
fsx:
  filesystemId: ${lookup(local.fsx, "file_system_id")}
  mountName: ${lookup(local.fsx, "mount_name")}
  dnsName: ${lookup(local.fsx, "dns_name")}
  storageSize: "${lookup(local.fsx, "capacity", 1200)}Gi"
YAML
  ]
}
