variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "instance_type" {
  type = string
  default = "db.t3.micro"
}

variable "instance_size" {
  type = string
  default = "10"
}

