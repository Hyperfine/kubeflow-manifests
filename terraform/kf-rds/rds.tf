data "aws_caller_identity" "current" {}

module "rds" {
  source = "git::git@github.com:Hyperfine/terraform-aws-service-catalog//modules/data-stores/rds?ref=v0.67.2"

  vpc_id = var.vpc_id
  subnet_ids = var.private_subnet_ids

  name = "kf-${var.cluster_name}-rds"
  engine = "mysql"
  engine_version = "8.0.28"
  allocated_storage = var.allocated_storage

  db_config_secrets_manager_id = var.secrets_manager_id

  cmk_administrator_iam_arns = var.cmk_administrator_iam_arns
  cmk_user_iam_arns = var.cmk_user_iam_arns

  apply_immediately = false

  # Deletion protection is a precaution to avoid accidental data loss by protecting the instance from being deleted.
  enable_deletion_protection = false
}

