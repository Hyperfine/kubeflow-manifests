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


# OPTIONAL PROVIDER CONFIG

variable "eks_cert_data" {
  type  = string
  nullable = true
}

variable "eks_endpoint" {
  type = string
  nullable = true
}