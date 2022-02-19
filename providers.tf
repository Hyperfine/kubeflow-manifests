provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
}

data aws_eks_cluster "eks" {
  name = "${var.cluster_name}"
}

locals {
  kubeconfig_context = "_terraform-kustomization-dl-demo_"

}

provider "kubectl" {
  host                   = "${data.aws_eks_cluster.eks.endpoint}"
  cluster_ca_certificate = <<EOT
${base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)}
EOT
  load_config_file       = false
  exec  {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = (
        ["eks", "get-token", "--cluster-name", "${data.aws_eks_cluster.eks.name}"]
      )
  }
}

provider "kustomization" {
  kubeconfig_raw = yamlencode({
    apiVersion = "v1"
    clusters = [
      {
        name = "${local.kubeconfig_context}"
        cluster = {
          certificate-authority-data = "${data.aws_eks_cluster.eks.certificate_authority.0.data}"
          server                     = "${data.aws_eks_cluster.eks.endpoint}"
        }
      }
    ]
    users = [
      {
        name = "${local.kubeconfig_context}"
        user = {
              exec = {
                apiVersion = "client.authentication.k8s.io/v1alpha1",
                command = "aws",
                args: ["--region",
                  "us-east-2",
                 "eks",
                 "get-token",
                 "--cluster-name",
                 "${data.aws_eks_cluster.eks.name}"
                ]
              }
        }
      }
    ]
    contexts = [
      {
        name = "${local.kubeconfig_context}"
        context = {
          cluster = "${local.kubeconfig_context}"
          user    = "${local.kubeconfig_context}"
        }
      }
    ]
  })

  context        = "${local.kubeconfig_context}"
}

provider "aws" {
  region = var.region
}

