data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

locals {
  oidc_id = trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")
}
