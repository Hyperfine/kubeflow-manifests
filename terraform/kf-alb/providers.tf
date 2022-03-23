provider "kubectl" {
  host                   = "${var.eks_endpoint}"
  cluster_ca_certificate = <<EOT
${base64decode(var.eks_cert_data)}
EOT
  load_config_file       = false
  exec  {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = (
        ["eks", "get-token", "--cluster-name", "${var.cluster_name}"]
      )
  }
}
