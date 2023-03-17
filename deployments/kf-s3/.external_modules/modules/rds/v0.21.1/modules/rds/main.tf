# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN RDS CLUSTER
# This template creates an Amazon Relational Database (RDS) cluster that can run MySQL, Postgres, or MariaDB. The
# cluster is managed by AWS and automatically handles standby failover, read replicas, backups, patching, and
# encryption.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  # This module is now only being tested with Terraform 1.0.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 1.0.x code.
  required_version = ">= 0.12.26"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  monitoring_role_name        = var.monitoring_role_name == null ? "${var.name}-monitoring-role" : var.monitoring_role_name
  db_subnet_group_name        = var.aws_db_subnet_group_name == null ? var.name : var.aws_db_subnet_group_name
  db_subnet_group_description = var.aws_db_subnet_group_description == null ? "Subnet group for the ${var.name} DB" : var.aws_db_subnet_group_description
  parameter_group_name = (
    var.parameter_group_name == null
    ? lookup(local.default_parameter_group_name, var.engine, local.fallback_parameter_group_name)
    : var.parameter_group_name
  )
  parameter_group_name_for_read_replicas = (
    var.parameter_group_name_for_read_replicas == null
    ? local.parameter_group_name
    : var.parameter_group_name_for_read_replicas
  )
  fallback_parameter_group_name = "default.${var.engine}${local.engine_version_major_minor}"
  final_snapshot_name           = var.final_snapshot_name == null ? "${var.name}-final-snapshot" : var.final_snapshot_name
  db_security_group_name        = var.aws_db_security_group_name == null ? var.name : var.aws_db_security_group_name
  db_security_group_description = var.aws_db_security_group_description == null ? "Security group for the ${var.name} DB" : var.aws_db_security_group_description
  engine_version_major          = replace(var.engine_version, "/(.+?)\\.(.+?)\\.*(.+)?/", "$1")
  engine_version_major_minor    = replace(var.engine_version, "/(.+?)\\.(.+?)\\..+/", "$1.$2")

  # This is a workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/2468. If we don't set
  # the parameter group name, RDS will show a diff every time you run plan, and exit with an error when you run
  # apply. The default parameter group value is of the format default.<DB><VERSION>, where DB is the database engine and
  # VERSION is the major.minor version number (but no patch!). However there are two exceptions - the first is PostgreSQL
  # version 10 and above. They use the format default.postgres<major> with no minor version. The second is SQL Server
  # which uses the format default.<DB>-<VERSION>, where VERSION is major.<MINOR>, where MINOR is the first digit
  # of the minor version number.
  default_parameter_group_name = {
    mysql = "default.mysql${local.engine_version_major_minor}"
    # correctly handle parameter group names like: default.postgres9.4 and default.postgres10.
    postgres      = "default.postgres${local.engine_version_major >= 10 ? local.engine_version_major : local.engine_version_major_minor}"
    sqlserver-ee  = "default.${var.engine}${replace(var.engine_version, "/(.+?)\\.(\\d).*?\\..+/", "-$1.$2")}"
    sqlserver-se  = "default.${var.engine}${replace(var.engine_version, "/(.+?)\\.(\\d).*?\\..+/", "-$1.$2")}"
    sqlserver-ex  = "default.${var.engine}${replace(var.engine_version, "/(.+?)\\.(\\d).*?\\..+/", "-$1.$2")}"
    sqlserver-web = "default.${var.engine}${replace(var.engine_version, "/(.+?)\\.(\\d).*?\\..+/", "-$1.$2")}"
  }
  # SQL Server needs a special workaround as its engine versions differ significantly from Postgres and MySQL.
  # We use the following Regex to turn an engine version like 14.00.3035.2.v1 into a parameter group name like:
  # default.sqlserver-ex-15.0.

  # Custom access control helpers for read replica instances
  create_security_group_for_read_replica = length(var.allow_connections_from_cidr_blocks_to_read_replicas) + length(var.allow_connections_from_security_groups_to_read_replicas) > 0
  read_replica_security_group_id = (
    local.create_security_group_for_read_replica
    ? aws_security_group.db_replica[0].id
    : aws_security_group.db.id
  )

  rds_instance = length(aws_db_instance.primary) > 0 ? aws_db_instance.primary[0] : aws_db_instance.instance_managed_password[0]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE PRIMARY DATABASE INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

# Optionally create a role that has permissions for enhanced monitoring
# This is only created if var.monitoring_interval and a role isn't explicitily set with
# var.monitoring_role_arn
resource "aws_iam_role" "enhanced_monitoring_role" {
  # The reason we use a count here is to ensure this resource is only created if var.monitoring_interval is set and
  # var.monitoring_role_arn is not provided
  count = var.monitoring_interval > 0 && var.monitoring_role_arn == null ? 1 : 0

  name               = local.monitoring_role_name
  path               = var.monitoring_role_arn_path
  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring_role.json

  # Workaround for a bug where Terraform sometimes doesn't wait long enough for the IAM role to propagate.
  # https://github.com/hashicorp/terraform/issues/4306
  # Workaround for a bug where Terraform sometimes doesn't wait long enough for the IAM role to propagate.
  # https://github.com/hashicorp/terraform/issues/4306
  provisioner "local-exec" {
    command = "echo 'Sleeping for 30 seconds to work around IAM Instance Profile propagation bug in Terraform' && sleep 30"
  }
}

data "aws_iam_policy_document" "enhanced_monitoring_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

# Connect the role to the AWS default policy for enhanced monitoring
resource "aws_iam_role_policy_attachment" "enhanced_monitoring_role_attachment" {
  count      = var.monitoring_interval > 0 && var.monitoring_role_arn == null ? 1 : 0
  depends_on = [aws_iam_role.enhanced_monitoring_role]
  role = element(
    concat(aws_iam_role.enhanced_monitoring_role.*.name, [""]),
    0,
  )
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "primary" {
  count               = var.ignore_password_changes ? 0 : 1
  deletion_protection = var.deletion_protection

  identifier     = var.name
  name           = var.db_name
  engine         = var.engine
  engine_version = var.engine_version
  license_model  = var.license_model == null ? local.default_license_model : var.license_model

  instance_class        = var.instance_type
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_arn
  storage_type          = var.storage_type
  iops                  = var.iops

  port = var.port

  # By default databases should not be publicly accessible.
  # Make publicly_accessible configurable so that end users can choose whether or not their db's are accessible to the open Internet.
  publicly_accessible = var.publicly_accessible

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = local.db_subnet_group_name
  parameter_group_name   = local.parameter_group_name
  option_group_name      = var.option_group_name

  username = var.master_username
  password = var.master_password

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  final_snapshot_identifier = local.final_snapshot_name
  skip_final_snapshot       = var.skip_final_snapshot

  snapshot_identifier = var.snapshot_identifier

  apply_immediately               = var.apply_immediately
  maintenance_window              = var.maintenance_window
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_role_arn != null ? var.monitoring_role_arn : local.auto_created_monitoring_role_arn
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  multi_az                        = var.multi_az
  ca_cert_identifier              = var.ca_cert_identifier

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period

  allow_major_version_upgrade = var.allow_major_version_upgrade

  tags                  = var.custom_tags
  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  replicate_source_db = var.replicate_source_db

  # We depend on aws_db_subnet_group, but due to the need to name things dynamically and using local vars, our code
  # doesn't reflect that dependency, so we have to call it out explicitly
  depends_on = [aws_db_subnet_group.db]

  # We ignore changes to the `snapshot_identifier` to avoid recreating the database after the database has been
  # restored. This makes sense because in almost all use cases of the `snapshot_identifier`, it only matters on when the
  # database is first spinning up (the first apply), and changes to this value after that would be unintentional. The
  # one use case is recreating the DB with a new snapshot, but in that use case the user should destroy the DB with
  # `terraform destroy` first.
  lifecycle {
    ignore_changes = [snapshot_identifier]
  }

  # We add timeouts, because sometimes MsSQL DB creation process takes more than 40m.
  timeouts {
    create = var.creating_timeout
    update = var.updating_timeout
    delete = var.deleting_timeout
  }
}

resource "aws_db_instance" "instance_managed_password" {
  count               = var.ignore_password_changes ? 1 : 0
  deletion_protection = var.deletion_protection

  identifier     = var.name
  name           = var.db_name
  engine         = var.engine
  engine_version = var.engine_version
  license_model  = var.license_model == null ? local.default_license_model : var.license_model

  instance_class        = var.instance_type
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_arn
  storage_type          = var.storage_type
  iops                  = var.iops

  port = var.port

  # By default databases should not be publicly accessible.
  # Make publicly_accessible configurable so that end users can choose whether or not their db's are accessible to the open Internet.
  publicly_accessible = var.publicly_accessible

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = local.db_subnet_group_name
  parameter_group_name   = local.parameter_group_name
  option_group_name      = var.option_group_name

  username = var.master_username
  password = var.master_password

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  final_snapshot_identifier = local.final_snapshot_name
  skip_final_snapshot       = var.skip_final_snapshot

  snapshot_identifier = var.snapshot_identifier

  apply_immediately               = var.apply_immediately
  maintenance_window              = var.maintenance_window
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_role_arn != null ? var.monitoring_role_arn : local.auto_created_monitoring_role_arn
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  multi_az                        = var.multi_az
  ca_cert_identifier              = var.ca_cert_identifier

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period

  allow_major_version_upgrade = var.allow_major_version_upgrade

  tags                  = var.custom_tags
  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  replicate_source_db = var.replicate_source_db

  # We depend on aws_db_subnet_group, but due to the need to name things dynamically and using local vars, our code
  # doesn't reflect that dependency, so we have to call it out explicitly
  depends_on = [aws_db_subnet_group.db]

  # We ignore changes to the `snapshot_identifier` to avoid recreating the database after the database has been
  # restored. This makes sense because in almost all use cases of the `snapshot_identifier`, it only matters on when the
  # database is first spinning up (the first apply), and changes to this value after that would be unintentional. The
  # one use case is recreating the DB with a new snapshot, but in that use case the user should destroy the DB with
  # `terraform destroy` first.

  # When the ignore_password_changes variable is true we ignore changes to the `password`.  This is useful when 
  # it is desired to manage an instance's password outside of terraform (ex. using AWS Secrets Manager Rotations). 
  lifecycle {
    ignore_changes = [snapshot_identifier, password]
  }

  # We add timeouts, because sometimes MsSQL DB creation process takes more than 40m.
  timeouts {
    create = var.creating_timeout
    update = var.updating_timeout
    delete = var.deleting_timeout
  }
}

locals {
  auto_created_monitoring_role_arn = (
    length(aws_iam_role.enhanced_monitoring_role) > 0
    ? aws_iam_role.enhanced_monitoring_role[0].arn
    : ""
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE READ REPLICAS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_db_instance" "replicas" {
  count = var.num_read_replicas

  deletion_protection = var.deletion_protection

  replicate_source_db = local.rds_instance.id
  identifier          = "${var.name}-replica-${count.index}"

  apply_immediately       = var.apply_immediately
  instance_class          = var.instance_type
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  storage_encrypted       = var.storage_encrypted
  kms_key_id              = var.kms_key_arn
  storage_type            = var.read_replica_storage_type == null ? var.storage_type : var.read_replica_storage_type
  iops                    = var.read_replica_iops == null ? var.iops : var.read_replica_iops
  ca_cert_identifier      = var.ca_cert_identifier
  availability_zone       = (var.allowed_replica_zones != null && length(var.allowed_replica_zones) > 0 ? element(var.allowed_replica_zones, count.index) : null)
  backup_retention_period = var.replica_backup_retention_period

  port = var.port

  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports

  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_role_arn != null ? var.monitoring_role_arn : local.auto_created_monitoring_role_arn
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period

  # By default databases should not be publicly accessible.
  # Make publicly_accessible configurable so that end users can choose whether or not their db's are accessible to the open Internet.
  publicly_accessible = var.publicly_accessible

  vpc_security_group_ids = [local.read_replica_security_group_id]
  parameter_group_name   = local.parameter_group_name_for_read_replicas

  # Replicas are not eligible for snapshots, but if we don't set this, you get an error preventing you from deleting
  # the replica. https://github.com/gruntwork-io/terraform-aws-data-storage/issues/42
  skip_final_snapshot = true

  # you'd think a replica would automatically pick up the setting from the master,
  # but the latest version of aws provider is now defaulting the value to true
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  tags                  = var.custom_tags
  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  # We depend on aws_db_subnet_group, but due to the need to name things dynamically and using local vars, our code
  # doesn't reflect that dependency, so we have to call it out explicitly
  depends_on = [aws_db_subnet_group.db]

  # We add timeouts, because sometimes MsSQL DB creation process takes more than 40m.
  timeouts {
    create = var.creating_timeout
    update = var.updating_timeout
    delete = var.deleting_timeout
  }
}

# ------------------------------------------------------------------------------
# CREATE THE SUBNET GROUP THAT SPECIFIES IN WHICH SUBNETS TO DEPLOY THE DB INSTANCES
# ------------------------------------------------------------------------------

resource "aws_db_subnet_group" "db" {
  count = var.create_subnet_group ? 1 : 0

  name        = local.db_subnet_group_name
  description = local.db_subnet_group_description
  subnet_ids  = var.subnet_ids
  tags = merge(
    { Name = "The subnet group for the ${var.name} DB" },
    var.custom_tags,
  )
}

# ------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT CONTROLS WHAT TRAFFIC CAN CONNECT TO THE DB
# ------------------------------------------------------------------------------

resource "aws_security_group" "db" {
  name        = local.db_security_group_name
  description = local.db_security_group_description
  vpc_id      = var.vpc_id
  tags        = var.custom_tags
}

resource "aws_security_group_rule" "allow_connections_from_cidr_blocks" {
  count             = signum(length(var.allow_connections_from_cidr_blocks))
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.allow_connections_from_cidr_blocks
  security_group_id = aws_security_group.db.id
}

resource "aws_security_group_rule" "allow_connections_from_security_group" {
  count                    = length(var.allow_connections_from_security_groups)
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = element(var.allow_connections_from_security_groups, count.index)
  security_group_id        = aws_security_group.db.id
}

# ------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT CONTROLS WHAT TRAFFIC CAN CONNECT TO THE DB READ REPLICAS
# Note that we only create a separate Security Group for the read replicas if the user specifies
# var.allow_connections_from_cidr_blocks_to_read_replicas and/or var.allow_connections_from_security_groups_to_read_replicas.
# Otherwise, the replicas will use the same security group as the primary.
# ------------------------------------------------------------------------------

resource "aws_security_group" "db_replica" {
  count = local.create_security_group_for_read_replica ? 1 : 0

  name        = "${var.name}-read-replica"
  description = "Security group for the ${var.name}-read-replica DB"
  vpc_id      = var.vpc_id
  tags        = var.custom_tags
}

resource "aws_security_group_rule" "allow_connections_from_cidr_blocks_to_read_replica" {
  count             = signum(length(var.allow_connections_from_cidr_blocks_to_read_replicas))
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.allow_connections_from_cidr_blocks_to_read_replicas
  security_group_id = aws_security_group.db_replica[0].id
}

resource "aws_security_group_rule" "allow_connections_from_security_group_to_read_replica" {
  count                    = length(var.allow_connections_from_security_groups_to_read_replicas)
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = element(var.allow_connections_from_security_groups_to_read_replicas, count.index)
  security_group_id        = aws_security_group.db_replica[0].id
}

# ---------------------------------------------------------------------------------------------------------------------
# WORKAROUNDS
# ---------------------------------------------------------------------------------------------------------------------

# This is another workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/2468, but this
# time for the license model. If we leave it blank, you get a diff every time you run plan, so we have to select a
# default license type for the DB engine.
locals {
  default_license_model = var.default_license_models[var.engine]
}
