terraform {
  required_providers {
    okta = {
      source = "okta/okta"
      version = "~> 3.20"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "< 4.0"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = var.use_exec_plugin_for_auth ? null : data.aws_eks_cluster_auth.kubernetes_token[0].token

  # EKS clusters use short-lived authentication tokens that can expire in the middle of an 'apply' or 'destroy'. To
  # avoid this issue, we use an exec-based plugin here to fetch an up-to-date token. Note that this code requires a
  # binary—either kubergrunt or aws—to be installed and on your PATH.
  dynamic "exec" {
    for_each = var.use_exec_plugin_for_auth ? ["once"] : []

    content {
      api_version = "client.authentication.k8s.io/v1alpha1"
      command     = var.use_kubergrunt_to_fetch_token ? "kubergrunt" : "aws"
      args = (
        var.use_kubergrunt_to_fetch_token
        ? ["eks", "token", "--cluster-id", var.eks_cluster_name]
        : ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
      )
    }
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  load_config_file       = false
  exec  {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = (
        ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
      )
  }
}

provider "okta" {
  org_name  = var.org_name
  base_url  = var.base_url
  api_token = var.api_token
}

data okta_users "okta_users" {
  group_id = var.okta_group_id
}

module "user" {
  for_each =  data.okta_users.okta_users.users
  source = "./../users"
  username = each.value["email"]
}
