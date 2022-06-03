data "aws_caller_identity" "current" {}

locals {
  oidc_id = trimprefix(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://")
}

data aws_secretsmanager_secret "rds" {
  name = var.rds_secret_name
}

data aws_secretsmanager_secret "s3" {
  name = var.s3_secret_name
}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "kubernetes_token" {
  count = var.use_exec_plugin_for_auth ? 0 : 1
  name  = var.eks_cluster_name
}