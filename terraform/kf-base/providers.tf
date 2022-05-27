provider aws {
  region = var.region
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
          certificate-authority-data = var.eks_cert_data
          server                     = var.eks_endpoint
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
            args = ["--region", "${var.region}", "eks", "get-token", "--cluster-name", "${var.cluster_name}"]
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