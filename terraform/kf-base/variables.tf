variable "region" {
  type = string
  default = "us-east-2"
}

variable "cluster_name" {
  type = string
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