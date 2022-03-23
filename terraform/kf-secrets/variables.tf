variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "rds_secret" {
  type = string
}

variable "s3_secret" {
  type = string
}

variable "oidc_url" {
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