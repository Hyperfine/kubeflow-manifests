variable "region" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_name" {
  type = string
  default = "hyperfine-demo-vpc"
}

variable "first_run" {
  type = bool
  default = false
}

variable "efs_name" {
  type = string

}