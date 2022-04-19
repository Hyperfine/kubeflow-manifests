resource aws_db_subnet_group "private" {
  name = "private"
  subnet_ids = data.aws_subnets.private.ids
}

module "rds" {
  source = "git::git@github.com:Hyperfine/terraform-aws-service-catalog//modules/data-stores/rds?ref=v0.66.2.0"

  name = "kf-${var.cluster_name}-rds"
  engine = "mysql"
  engine_version = "8.0.28"
  port = local.rds_info["port"]
  db_name = local.rds_info["database"]

  master_username = local.rds_info["username"]
  master_password = local.rds_info["password"]
}


resource "aws_secretsmanager_secret" "rds-secret" {
  name = "${var.cluster_name}-kf-rds-secret"
  kms_key_id = var.kms_key_id
  recovery_window_in_days = 0
}

# minio requires rds info to access
resource "aws_secretsmanager_secret_version" "rds_version" {
  secret_id = aws_secretsmanager_secret.rds-secret.id
  secret_string = jsonencode(local.rds_info)
}


locals {
  rds_info = {
    "username" : var.username,
    "password" : var.password,
    "database" : "kubeflow",
    "host" : module.rds.outputs.primary_host,
    "port" : "3306"
  }
}
