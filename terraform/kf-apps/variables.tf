variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "bucket" {
  type = string
}

variable "rds_secret_version_arn" {
  type = string
}


# PROVIDER CONFIG

variable "eks_cert_data" {
  type  = string
}

variable "eks_endpoint" {
  type = string
}