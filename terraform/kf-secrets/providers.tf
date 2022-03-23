provider "kubectl" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
  load_config_file       = false
}

locals {
  # non-default context name to protect from using wrong kubeconfig
  kubeconfig_context = "_terraform-kustomization-${var.cluster_name}_"

  kubeconfig = {
    apiVersion = "v1"
    clusters = [
      {
        name = local.kubeconfig_context
        cluster = {
          certificate-authority-data = data.aws_eks_cluster.eks.certificate_authority.0.data
          server                     = data.aws_eks_cluster.eks.endpoint
        }
      }
    ]
    users = [
      {
        name = local.kubeconfig_context
        user = {
          token = data.aws_eks_cluster_auth.eks.token
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