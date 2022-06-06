variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "eks_iam_openid_connect_provider_arn" {
  type = string
}

variable "eks_iam_openid_connect_provider_url" {
  type = string
}

variable "zone_id" {
  type = string
}
/*

variable "kubeflow_name" {
  type = string
}

/*
variable "alb_dns_name" {
  type = string
}
*/

# PROVIDER CONFIG

variable "eks_cert_data" {
  type  = string
  default = ""
}

variable "eks_endpoint" {
  type = string
  default = ""
}