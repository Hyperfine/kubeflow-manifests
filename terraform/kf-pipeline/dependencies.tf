data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "kubernetes_token" {
  count = var.use_exec_plugin_for_auth ? 0 : 1
  name  = var.eks_cluster_name
}

data aws_secretsmanager_secret "rds" {
  arn = var.rds_secret_version_arn
}

data aws_secretsmanager_secret_version "rds_info" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}

locals {
  rds_info = jsondecode(data.aws_secretsmanager_secret_version.rds_info.secret_string)
  oidc_id = trimprefix(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://")
}
