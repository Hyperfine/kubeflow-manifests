data aws_secretsmanager_secret "rds" {
  arn = var.rds_secret_version_arn
}

data aws_secretsmanager_secret_version "rds_info" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}

locals {
  rds_info = jsondecode(data.aws_secretsmanager_secret_version.rds_info.secret_string)
}
