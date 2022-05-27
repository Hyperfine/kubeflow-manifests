data "aws_caller_identity" "current" {}

locals {
  oidc_id = trimprefix(var.oidc_url, "https://")
}

data aws_secretsmanager_secret "rds" {
  name = var.rds_secret_name
}

data aws_secretsmanager_secret "s3" {
  name = var.s3_secret_name
}