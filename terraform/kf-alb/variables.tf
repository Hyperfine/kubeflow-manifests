variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "oidc_url" {
  type = string
}

variable "cert_arn" {
  type = string
}

variable "pool_arn" {
  type = string
}
variable "cognito_client_id" {
  type = string
}

variable "cognito_domain" {
  type = string
}

# PROVIDER CONFIG

variable "eks_cert_data" {
  type  = string
}

variable "eks_endpoint" {
  type = string
}