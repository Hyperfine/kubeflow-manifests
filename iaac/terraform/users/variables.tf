
variable "username" {
  type = string
}

variable "rds_secret_name" {
  type = string
}

variable "s3_secret_name" {
  type = string
}

variable "ssh_key_secret_name" {
  type = string
}

variable "kms_key_ids" {
  type = list(string)
}

variable "eks_cluster_name" {
  type = string
}
