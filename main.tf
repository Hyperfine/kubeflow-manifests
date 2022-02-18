terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.74"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.7.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

module "pre" {
  source = "./terraform/stage_0"

  cluster_name = var.cluster_name
  domain_name  = var.domain_name
  region       = var.region
  efs_name = "dl-cluster-data"
  vpc_id = var.vpc_id
}


module "ingress" {
  source = "./terraform/stage_1"
  region = var.region
  cluster_name = var.cluster_name

  cert_arn = module.pre.cert_arn
  pool_arn = module.pre.pool_arn
  cognito_client_id = module.pre.cognito_client_id
  cognito_domain = module.pre.cognito_domain
}

module "main" {
  source = "./terraform/stage_2"
  region = var.region
  cluster_name = var.cluster_name
  bucket = module.pre.bucket
  secret_id = module.pre.secret_id
}

module "post" {
  depends_on = [module.main]
  source = "./terraform/stage_3"

  region = var.region
  domain_name = var.domain_name
  cluster_name = var.cluster_name
}

