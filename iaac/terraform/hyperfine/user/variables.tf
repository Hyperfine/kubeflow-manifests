
variable "username" {
  description = "namespace to use for username"
  type = string
}

variable "rds_secret_name" {
  description = "secretmamanger secet for rds access"
  type = string
}

variable "s3_secret_name" {
  description = "secretmanager secret for s3 access"
  type = string
}

variable "ssh_key_secret_name" {
  description = "secretmanager secret for user's ssh key"
  type = string
}

variable "efs_storage_class_name" {
  description = "efs storage class name to create pvc for"
  type = string
  default = "dl-efs-home-sc"
}

variable "kms_key_ids" {
  description = "list of kms "
  type = list(string)
}

variable "eks_cluster_name" {
  description = "cluster to install to"
  type = string
}
