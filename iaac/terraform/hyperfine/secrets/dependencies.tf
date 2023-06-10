data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "kubernetes_token" {
  count = var.use_exec_plugin_for_auth ? 0 : 1
  name  = var.eks_cluster_name
}


data "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket_name
}

data "aws_secretsmanager_secret" "rds" {
  name = var.rds_secret_name
}

data "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}

locals {
  rds_secret = jsondecode(data.aws_secretsmanager_secret_version.rds_secret_version.secret_string)
  oidc_id    = trimprefix(data.aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer, "https://")

}