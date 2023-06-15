# access key info
variable "s3_bucket_name" {
  description = "bucket to access"
  type        = string
}

variable "rds_secret_name" {
  description = "secretmaanger for rds config"
  type        = string
}

variable "rds_host" {
  description = "rds host name to use"
  type        = string
}

variable "s3_region" {
  description = "region for s3 bucket"
  type        = string
  default     = "us-east-1"
}

# optional

variable "namespace" {
  description = "namespace to create secrets in"
  type = string
  default = "kubeflow"
}

variable "service_account_name" {
  description = "name of service account to use"
  type = string
  default = "kf-secrets-manager-sa"
}

variable "additional_kms_key_arns" {
  description = "list of kms keys to add to"
  type        = list(string)
  default     = []
}


# PROVIDER CONFIGS
variable "eks_cluster_name" {
  description = "cluster to install kubeflow to"
  type        = string
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