provider aws {
  region = var.region
}



provider "helm" {
  kubernetes {
    host                   = var.eks_endpoint
    cluster_ca_certificate = base64decode(var.eks_cert_data)
    exec  {
      api_version = "client.authentication.k8s.io/v1alpha1"
      command     = "aws"
      args = (
          ["eks", "get-token", "--cluster-name", "${var.cluster_name}"]
        )
    }
  }
}

provider "kubernetes" {
host = var.eks_endpoint
cluster_ca_certificate = base64decode(var.eks_cert_data)
exec {
  api_version = "client.authentication.k8s.io/v1alpha1"
  args = ["eks", "get-token", "--cluster-name", var.cluster_name]
  command = "aws"
 }
}

