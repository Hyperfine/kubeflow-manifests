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

variable "rds_info" {
  type = map
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