variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "top_zone_id" {
  type = string
}

variable "subdomain_name" {
  type = string
}

# OPTIONAL

variable "first_run" {
  type = bool
  default = false
}

variable "public_acm" {
  type = bool
  default = true
}
