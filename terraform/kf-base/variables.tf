variable "region" {
  type = string
  default = "us-east-2"
}

variable "cluster_name" {
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