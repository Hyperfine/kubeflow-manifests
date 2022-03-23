data aws_eks_cluster "eks" {
  name = var.cluster_name
}


data aws_eks_cluster_auth "eks" {
  name = data.aws_eks_cluster.eks.name
}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "rds-secret" {
  name = var.rds_secret
}

data "aws_secretsmanager_secret" "s3-secret" {
  name = var.s3_secret
}

locals {
  oidc_id = trimprefix(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://")
  rds_secret = data.aws_secretsmanager_secret.rds-secret.name
  s3_secret = data.aws_secretsmanager_secret.s3-secret.name
}
