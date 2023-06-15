# access key

variable "s3_bucket_name" {
  description = "bucket to access"
  type = string
}

variable "rds_secret_name" {
  description = "secretmaanger for rds config"
  type = string
}

variable "rds_host" {
  description = "rds host name to use"
  type = string
}

# dex configurations

variable subdomain {
  description = "subdomain used to access dex"
  type = string
  default = "platform"
}

variable dex_version {
  description = "helm chart version for dex"
  type = string
  default = "0.14.1"
}

variable zone_id {
  description = "top level zone to use fo domain"
  type = string
}

variable okta_secret_name {
  description = "secretmanager name to use for okta"
  type = string
  # secret format
  # {
  #   "okta_client_id":"asdfasdf",
  #    "okta_client_secret":"asdfasdf",
  #    "okta_issuer_url":"https://hyperfine.okta.com",
  #    "okta_client_id_":"asdfasdf",
  #    "okta_client_secret_":"asdfasdf-asdfasdfG",
  #    "okta_issuer_url_":"https://dev-1111111.okta.com"
  #  }
}

variable oidc_secret_name {
  description = "secretmanager name to use for auth service"
  type = string
  # secret format
  # {
  #  "auth_client_id":"kf-oidc-authservice",
  #   "auth_client_secret":"asdfasdf"
  #  }
}

variable oidc_sa_name {
  description = "service account name to use for oidc"
  type        = string
  default     = "oidc-secrets-manager-sa"
}

variable   auth_namespace {
  description = "namespace to deploy auth service to"
  type        = string
  default     = "auth"
}

# user configurations

variable users {
  description = "map of usernames to ssh secret"
  type        = map(string)
}


# PROVIDER CONFIGS
variable "eks_cluster_name" {
  description = "cluster to install to"
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