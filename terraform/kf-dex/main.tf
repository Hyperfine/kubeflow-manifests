terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.8.1"
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

provider "helm" {
  kubernetes {
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


locals {
  # non-default context name to protect from using wrong kubeconfig
  kubeconfig_context = "_terraform-kustomization-${var.eks_cluster_name}_"

  kubeconfig = {
    apiVersion = "v1"
    clusters = [
      {
        name = local.kubeconfig_context
        cluster = {
          certificate-authority-data = data.aws_eks_cluster.cluster.certificate_authority.0.data
          server                     = data.aws_eks_cluster.cluster.endpoint
        }
      }
    ]
    users = [
      {
        name = local.kubeconfig_context
        user = {
          exec = {
            apiVersion = "client.authentication.k8s.io/v1alpha1",
            command = "aws"
            args = ["--region", var.aws_region, "eks", "get-token", "--cluster-name", var.eks_cluster_name]
          }
        }
      }
    ]
    contexts = [
      {
        name = local.kubeconfig_context
        context = {
          cluster = local.kubeconfig_context
          user    = local.kubeconfig_context
        }
      }
    ]
  }
}

provider "kustomization" {
  kubeconfig_raw = yamlencode(local.kubeconfig)
  context        = local.kubeconfig_context
}
