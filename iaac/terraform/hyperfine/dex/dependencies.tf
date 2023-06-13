data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "kubernetes_token" {
  count = var.use_exec_plugin_for_auth ? 0 : 1
  name  = var.eks_cluster_name
}

data "aws_route53_zone" "top_level" {
  zone_id = var.zone_id
}


data "aws_secretsmanager_secret" "oidc_secrets" {
  for_each = local.oidc_secret_names
  name     = each.key
}


locals {
  oidc_id           = trimprefix(data.aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer, "https://")
  oidc_secret_names = toset([var.oidc_secret_name, var.okta_secret_name])
}

