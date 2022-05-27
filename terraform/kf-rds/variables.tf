variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "instance_type" {
  type = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type = number
  default = 10
}


variable "cmk_administrator_iam_arns" {
  type = list(string)
}

variable "cmk_user_iam_arns" {
  type = any

}