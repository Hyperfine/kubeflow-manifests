variable "region" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "subdomain_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "first_run" {
  type = bool
  default = false
}

variable "efs_name" {
  type = string

}