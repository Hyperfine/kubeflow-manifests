variable "aws_region" {
  type = string
}

variable subdomain {
  type = string
  default = "platform"
}

variable zone_id {
  type = string
}

variable okta_issuer_url {
  type = string
}

variable okta_client_id {
  type = string
}

variable okta_client_secret {
  type = string
}


variable dex_version {
  type = string
  default = "0.8.3"
}

# PROVIDER CONFIG

variable "eks_cluster_name" {
  type = string
}

variable "use_exec_plugin_for_auth" {
  description = "If this variable is set to true, then use an exec-based plugin to authenticate and fetch tokens for EKS. This is useful because EKS clusters use short-lived authentication tokens that can expire in the middle of an 'apply' or 'destroy', and since the native Kubernetes provider in Terraform doesn't have a way to fetch up-to-date tokens, we recommend using an exec-based provider as a workaround. Use the use_kubergrunt_to_fetch_token input variable to control whether kubergrunt or aws is used to fetch tokens."
  type        = bool
  default     = true
}

variable "use_kubergrunt_to_fetch_token" {
  description = "EKS clusters use short-lived authentication tokens that can expire in the middle of an 'apply' or 'destroy'. To avoid this issue, we use an exec-based plugin to fetch an up-to-date token. If this variable is set to true, we'll use kubergrunt to fetch the token (in which case, kubergrunt must be installed and on PATH); if this variable is set to false, we'll use the aws CLI to fetch the token (in which case, aws must be installed and on PATH). Note this functionality is only enabled if use_exec_plugin_for_auth is set to true."
  type        = bool
  default     = true
}