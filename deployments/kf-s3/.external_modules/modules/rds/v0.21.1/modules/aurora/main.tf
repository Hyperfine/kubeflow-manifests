# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN RDS CLUSTER WITH AMAZON AURORA
# This module deploys an RDS cluster with Amazon Aurora. The cluster is managed by AWS and automatically handles leader
# election, replication, failover, backups, patching, and encryption.
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
# SET MODULE DEPENDENCY RESOURCE
# This works around a terraform limitation where we can not specify module dependencies natively.
# See https://github.com/hashicorp/terraform/issues/1178 for more discussion.
# By resolving and computing the dependencies list, we are able to make all the resources in this module depend on the
# resources backing the values in the dependencies list.
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "dependency_getter" {
  triggers = {
    instance = join(",", var.dependencies)
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  db_subnet_group_name          = var.aws_db_subnet_group_name == null ? var.name : var.aws_db_subnet_group_name
  db_subnet_group_description   = var.aws_db_subnet_group_description == null ? "Subnet group for the ${var.name} DB" : var.aws_db_subnet_group_description
  db_security_group_name        = var.aws_db_security_group_name == null ? var.name : var.aws_db_security_group_name
  db_security_group_description = var.aws_db_security_group_description == null ? "Security group for the ${var.name} DB" : var.aws_db_security_group_description

  # The link to the DB subnet group depending on if it was created in the module or not.
  db_subnet_group_link = var.create_subnet_group ? aws_db_subnet_group.cluster[0].name : local.db_subnet_group_name

  rds_cluster = length(aws_rds_cluster.cluster) > 0 ? aws_rds_cluster.cluster[0] : aws_rds_cluster.cluster_managed_password[0]
}

# ------------------------------------------------------------------------------
# CREATE THE RDS CLUSTER
# In Terraform, the aws_rds_cluster resource is used *only* for Aurora. See aws_db_instance for other types of RDS
# databases.
# ------------------------------------------------------------------------------

resource "aws_rds_cluster" "cluster" {
  count              = var.ignore_password_changes ? 0 : 1
  cluster_identifier = var.name
  port               = var.port

  engine         = var.engine
  engine_version = var.engine_version
  engine_mode    = var.engine_mode

  # Cluster identifier for global databases. 
  global_cluster_identifier = var.global_cluster_identifier

  # Replication source ID and region if the RDS cluster is a read replica or a secondary in a global database
  replication_source_identifier = var.replication_source_identifier
  source_region                 = var.source_region

  db_subnet_group_name            = local.db_subnet_group_link
  vpc_security_group_ids          = [aws_security_group.cluster.id]
  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name

  database_name   = var.db_name
  master_username = var.master_username

  master_password              = var.master_password
  preferred_maintenance_window = var.preferred_maintenance_window
  preferred_backup_window      = var.preferred_backup_window
  backup_retention_period      = var.backup_retention_period
  backtrack_window             = var.backtrack_window

  # Due to a bug in Terraform, there is no way to disable the final snapshot in Aurora, so we always create one (which
  # is probably a safe default anyway, but a bit annoying for testing). For more info, see:
  # https://github.com/hashicorp/terraform/issues/6786
  final_snapshot_identifier = "${var.name}-final-snapshot"

  snapshot_identifier = var.snapshot_identifier

  enable_http_endpoint = var.enable_http_endpoint

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately
  storage_encrypted           = var.storage_encrypted
  kms_key_id                  = var.kms_key_arn

  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot

  iam_roles = var.cluster_iam_roles

  tags                  = var.custom_tags
  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  dynamic "scaling_configuration" {
    # The contents of the list in this for_each are not used. All that matters is if the list has 1 item in it, which
    # will result in the block being created, or 0 items, which will result in the block being omitted.
    for_each = var.engine_mode == "serverless" ? ["include"] : []
    content {
      auto_pause               = var.scaling_configuration_auto_pause
      max_capacity             = var.scaling_configuration_max_capacity
      min_capacity             = var.scaling_configuration_min_capacity
      seconds_until_auto_pause = var.scaling_configuration_seconds_until_auto_pause
      timeout_action           = var.scaling_configuration_timeout_action
    }
  }

  depends_on = [null_resource.dependency_getter]

  # We ignore changes to the `snapshot_identifier` to avoid recreating the database after the database has been
  # restored. This makes sense because in almost all use cases of the `snapshot_identifier`, it only matters on when the
  # database is first spinning up (the first apply), and changes to this value after that would be unintentional. The
  # one use case is recreating the DB with a new snapshot, but in that use case the user should destroy the DB with
  # `terraform destroy` first.
  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}

resource "aws_rds_cluster" "cluster_managed_password" {
  count              = var.ignore_password_changes ? 1 : 0
  cluster_identifier = var.name
  port               = var.port

  engine         = var.engine
  engine_version = var.engine_version
  engine_mode    = var.engine_mode

  # Cluster identifier for global databases. 
  global_cluster_identifier = var.global_cluster_identifier

  # Replication source ID and region if the RDS cluster is a read replica or a secondary in a global database
  replication_source_identifier = var.replication_source_identifier
  source_region                 = var.source_region

  db_subnet_group_name            = local.db_subnet_group_link
  vpc_security_group_ids          = [aws_security_group.cluster.id]
  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name

  database_name   = var.db_name
  master_username = var.master_username

  master_password              = var.master_password
  preferred_maintenance_window = var.preferred_maintenance_window
  preferred_backup_window      = var.preferred_backup_window
  backup_retention_period      = var.backup_retention_period
  backtrack_window             = var.backtrack_window

  # Due to a bug in Terraform, there is no way to disable the final snapshot in Aurora, so we always create one (which
  # is probably a safe default anyway, but a bit annoying for testing). For more info, see:
  # https://github.com/hashicorp/terraform/issues/6786
  final_snapshot_identifier = "${var.name}-final-snapshot"

  snapshot_identifier = var.snapshot_identifier

  enable_http_endpoint = var.enable_http_endpoint

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately
  storage_encrypted           = var.storage_encrypted
  kms_key_id                  = var.kms_key_arn

  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot

  iam_roles = var.cluster_iam_roles

  tags                  = var.custom_tags
  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  dynamic "scaling_configuration" {
    # The contents of the list in this for_each are not used. All that matters is if the list has 1 item in it, which
    # will result in the block being created, or 0 items, which will result in the block being omitted.
    for_each = var.engine_mode == "serverless" ? ["include"] : []
    content {
      auto_pause               = var.scaling_configuration_auto_pause
      max_capacity             = var.scaling_configuration_max_capacity
      min_capacity             = var.scaling_configuration_min_capacity
      seconds_until_auto_pause = var.scaling_configuration_seconds_until_auto_pause
      timeout_action           = var.scaling_configuration_timeout_action
    }
  }

  depends_on = [null_resource.dependency_getter]

  # We ignore changes to the `snapshot_identifier` to avoid recreating the database after the database has been
  # restored. This makes sense because in almost all use cases of the `snapshot_identifier`, it only matters on when the
  # database is first spinning up (the first apply), and changes to this value after that would be unintentional. The
  # one use case is recreating the DB with a new snapshot, but in that use case the user should destroy the DB with
  # `terraform destroy` first.

  # When the ignore_password_changes variable is true we ignore changes to the `master_password`.  This is useful when 
  # it is desired to manage a cluster's password outside of terraform (ex. using AWS Secrets Manager Rotations). 
  lifecycle {
    ignore_changes = [snapshot_identifier, master_password]
  }
}

# Get the current AWS region
data "aws_region" "current" {}

# Get the current AWS account
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# CREATE THE AURORA INSTANCES THAT RUN IN THE CLUSTER
# Note that in Terraform, the aws_rds_cluster_instance resource is used *only*
# for Aurora. See aws_db_instance for other types of RDS databases.
# ------------------------------------------------------------------------------

# Optionally create a role that has permissions for enhanced monitoring
# This is only created if var.monitoring_interval and a role isn't explicitily set with
# var.monitoring_role_arn
resource "aws_iam_role" "enhanced_monitoring_role" {
  # The reason we use a count here is to ensure this resource is only created if var.monitoring_interval is set and
  # var.monitoring_role_arn is not provided
  count = var.monitoring_interval > 0 && var.monitoring_role_arn == null ? 1 : 0

  name               = "${var.name}-monitoring-role"
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

resource "aws_rds_cluster_instance" "cluster_instances" {
  count = var.instance_count * (var.engine_mode == "serverless" ? 0 : 1)

  identifier         = "${var.name}-${count.index}"
  cluster_identifier = local.rds_cluster.id
  instance_class     = var.instance_type

  engine         = var.engine
  engine_version = var.engine_version

  # These DBs instances are not publicly accessible. They should live in a private subnet and only be accessible from
  # specific apps.
  publicly_accessible = var.publicly_accessible

  preferred_maintenance_window = local.cluster_instances_maintenance_window[count.index]
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade

  db_subnet_group_name    = local.db_subnet_group_link
  db_parameter_group_name = var.db_instance_parameter_group_name

  tags = var.custom_tags

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn != null ? var.monitoring_role_arn : local.auto_created_monitoring_role_arn

  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_kms_key_id

  ca_cert_identifier = var.ca_cert_identifier

  apply_immediately = var.apply_immediately

  lifecycle {
    # Ensure if recreating instances that new ones are added first
    create_before_destroy = true

    # Updates to engine_version will flow from aws_rds_cluster instead (https://github.com/terraform-providers/terraform-provider-aws/issues/9401)
    ignore_changes = [engine_version]
  }

  # Without this line, I consistently receive the following error: aws_rds_cluster.cluster: Error
  # modifying DB Instance xxx: DBInstanceNotFound: DBInstance not found: xxx. However, I am not 100% sure this resolves
  # the issue.
  depends_on = [aws_rds_cluster.cluster, aws_rds_cluster.cluster_managed_password]
}

locals {
  auto_created_monitoring_role_arn = (
    length(aws_iam_role.enhanced_monitoring_role) > 0
    ? aws_iam_role.enhanced_monitoring_role[0].arn
    : ""
  )

  # In order to calculate the maintenance window for each instance, the formula below is being used. After calculating the
  # result, each time will be formated to "day:hh:mm" and then concatenated to "${window_init_time}-${window_finish_time}",
  # e.g. "sat:17:50-sat:18:50".
  # window_init_time:   [window start timestamp + (minutes between windows * count)]
  # window_finish_time: {window start timestamp + [(minutes between windows * count) + maintenance duration]}
  cluster_instances_maintenance_window = [
    for i in range(var.instance_count) :
    "${lower(formatdate("EEE:hh:mm", timeadd(var.cluster_instances_maintenance_window_start_timestamp, "${var.cluster_instances_minutes_between_maintenance_windows * i}m")))}-${lower(formatdate("EEE:hh:mm", timeadd(var.cluster_instances_maintenance_window_start_timestamp, "${(var.cluster_instances_minutes_between_maintenance_windows * i) + var.cluster_instances_maintenance_duration_minutes}m")))}"
  ]
}

# ------------------------------------------------------------------------------
# CREATE THE SUBNET GROUP THAT SPECIFIES IN WHICH SUBNETS TO DEPLOY THE DB INSTANCES
# ------------------------------------------------------------------------------

resource "aws_db_subnet_group" "cluster" {
  count = var.create_subnet_group ? 1 : 0

  name        = local.db_subnet_group_name
  description = local.db_subnet_group_description
  subnet_ids  = var.subnet_ids
  tags = merge(
    {
      Name = "The subnet group for the ${var.name} DB"
    },
    var.custom_tags,
  )
}

# ------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT CONTROLS WHAT TRAFFIC CAN CONNECT TO THE DB
# ------------------------------------------------------------------------------

resource "aws_security_group" "cluster" {
  name        = local.db_security_group_name
  description = local.db_security_group_description
  vpc_id      = var.vpc_id
  tags        = var.custom_tags
}

resource "aws_security_group_rule" "allow_connections_from_cidr_blocks" {
  count       = signum(length(var.allow_connections_from_cidr_blocks))
  type        = "ingress"
  from_port   = var.port
  to_port     = var.port
  protocol    = "tcp"
  cidr_blocks = var.allow_connections_from_cidr_blocks

  security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "allow_connections_from_security_group" {
  count                    = length(var.allow_connections_from_security_groups)
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = element(var.allow_connections_from_security_groups, count.index)

  security_group_id = aws_security_group.cluster.id
}
