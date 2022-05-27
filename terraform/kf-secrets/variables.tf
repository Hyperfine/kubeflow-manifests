variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "rds_secret_name" {
  type = string
}

variable "s3_secret_name" {
  type = string
}

variable "oidc_url" {
  type = string
}

variable "kms_key_ids" {
  type = list(string)
  default = []
}

# PROVIDER CONFIG

variable "eks_cert_data" {
  type  = string
  default = ""
}

variable "eks_endpoint" {
  type = string
  default = ""
}