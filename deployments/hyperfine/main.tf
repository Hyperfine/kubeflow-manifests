terraform {
  required_version = ">= 1.2.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.71"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.13.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# create kubeflow namespace first
resource "kubernetes_namespace_v1" "kubeflow" {
  metadata {
    labels = {
      control-plane = "kubeflow"
      istio-injection = "enabled"
    }

    name = "kubeflow"
  }
}

module "secrets" {
  source = "../../iaac/terraform/hyperfine/secrets"

  eks_cluster_name = var.eks_cluster_name
  namespace = kubernetes_namespace_v1.kubeflow.metadata[0].name

  rds_host = var.rds_host
  rds_secret_name = var.rds_secret_name
  s3_bucket_name = var.s3_bucket_name
}

module "kubeflow" {
  source = "../../iaac/terraform/hyperfine/modules"

  eks_cluster_name = var.eks_cluster_name

  rds_host = module.secrets.rds_host
  s3_bucket_name = module.secrets.s3_bucket_name
}


module "dex" {
  source = "../../iaac/terraform/hyperfine/dex"

  eks_cluster_name = var.eks_cluster_name

  zone_id = var.zone_id
  oidc_secret_name = var.oidc_secret_name
  okta_secret_name = var.okta_secret_name

  subdomain = "blue"
}

/*
module "user" {
  for_each = var.users
  source = "../../iaac/terraform/hyperfine/user"
  username = each.key
  eks_cluster_name = var.eks_cluster_name

  ssh_key_secret_name = each.value

  rds_secret_name = module.secrets.rds_secret_name
  s3_secret_name = module.secrets.s3_secret_name
  kms_key_ids = module.secrets.kms_key_ids
}
*/
