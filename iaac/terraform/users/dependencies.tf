data "aws_caller_identity" "current" {}

locals {
  oidc_id = trimprefix(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://")
  secret_names = toset([var.rds_secret_name, var.s3_secret_name, var.ssh_key_secret_name])
}

data aws_secretsmanager_secret "secrets" {
  for_each = local.secret_names
  name = each.key
}


data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}
