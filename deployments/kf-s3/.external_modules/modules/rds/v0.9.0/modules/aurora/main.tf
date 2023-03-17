# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN RDS CLUSTER WITH AMAZON AURORA
# This module deploys an RDS cluster with Amazon Aurora. The cluster is managed by AWS and automatically handles leader
# election, replication, failover, backups, patching, and encryption.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ------------------------------------------------------------------------------
# CREATE THE RDS CLUSTER
# In Terraform, the aws_rds_cluster resource is used *only* for Aurora. See aws_db_instance for other types of RDS
# databases.
#
# Note, we have two aws_rds_cluster resources, although only one gets created, based on whether var.storage_encrypted
# is set to true or false. This is because of a limitation in Terraform (and AWS) where you can only set the kms_key_id
# parameter if storage_encrypted is set to true; if you set the kms_key_id parameter to any value, even an empty
# string, when storage_encrypted is false, you get an error. For more info, see:
# https://github.com/gruntwork-io/module-data-storage/issues/19
# ------------------------------------------------------------------------------

resource "null_resource" "validate_encryption_and_serverless_modes" {
  count = var.engine_mode == "serverless" && var.storage_encrypted == false ? 1 : 0
  triggers = {
    id = timestamp()
  }

  provisioner "local-exec" {
    command = "python -c \"raise Exception('ERROR: You must have encrypted storage when using serverless mode')\""
  }
}

resource "aws_rds_cluster" "cluster_with_encryption_serverless" {
  count = var.storage_encrypted && var.engine_mode == "serverless" ? 1 : 0

  cluster_identifier = var.name
  port               = var.port

  engine         = var.engine
  engine_version = var.engine_version
  engine_mode    = var.engine_mode

  db_subnet_group_name            = aws_db_subnet_group.cluster.name
  vpc_security_group_ids          = [aws_security_group.cluster.id]
  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name

  database_name   = var.db_name
  master_username = var.master_username

  # If the RDS Cluster is being restored from a snapshot, the password entered by the user is ignored.
  master_password = var.snapshot_identifier == null ? var.master_password : null

  preferred_maintenance_window = var.preferred_maintenance_window
  preferred_backup_window      = var.preferred_backup_window
  backup_retention_period      = var.backup_retention_period

  # Due to a bug in Terraform, there is no way to disable the final snapshot in Aurora, so we always create one (which
  # is probably a safe default anyway, but a bit annoying for testing). For more info, see:
  # https://github.com/hashicorp/terraform/issues/6786
  final_snapshot_identifier = "${var.name}-final-snapshot"

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  snapshot_identifier             = var.snapshot_identifier

  apply_immediately = var.apply_immediately
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_arn

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  scaling_configuration {
    auto_pause               = var.scaling_configuration_auto_pause
    max_capacity             = var.scaling_configuration_max_capacity
    min_capacity             = var.scaling_configuration_min_capacity
    seconds_until_auto_pause = var.scaling_configuration_seconds_until_auto_pause
  }

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  tags = var.custom_tags
}

resource "aws_rds_cluster" "cluster_with_encryption_provisioned" {
  count = var.storage_encrypted && var.engine_mode == "provisioned" ? 1 : 0

  cluster_identifier = var.name
  port               = var.port

  engine         = var.engine
  engine_version = var.engine_version
  engine_mode    = var.engine_mode

  db_subnet_group_name            = aws_db_subnet_group.cluster.name
  vpc_security_group_ids          = [aws_security_group.cluster.id]
  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name

  database_name   = var.db_name
  master_username = var.master_username

  # If the RDS Cluster is being restored from a snapshot, the password entered by the user is ignored.
  master_password = var.snapshot_identifier == null ? var.master_password : null

  preferred_maintenance_window = var.preferred_maintenance_window
  preferred_backup_window      = var.preferred_backup_window
  backup_retention_period      = var.backup_retention_period

  # Due to a bug in Terraform, there is no way to disable the final snapshot in Aurora, so we always create one (which
  # is probably a safe default anyway, but a bit annoying for testing). For more info, see:
  # https://github.com/hashicorp/terraform/issues/6786
  final_snapshot_identifier = "${var.name}-final-snapshot"

  snapshot_identifier = var.snapshot_identifier

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  apply_immediately = var.apply_immediately
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_arn

  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot

  tags = var.custom_tags
}

# Note, since this is no encryption and serverless requires encryption, there's no auto scaling configuration block here.  Also
# why there's no engine mode, as it's only relevant for encrypted systems
resource "aws_rds_cluster" "cluster_without_encryption" {
  count = var.storage_encrypted ? 0 : 1

  cluster_identifier = var.name
  port               = var.port

  engine         = var.engine
  engine_version = var.engine_version

  db_subnet_group_name            = aws_db_subnet_group.cluster.name
  vpc_security_group_ids          = [aws_security_group.cluster.id]
  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name

  database_name   = var.db_name
  master_username = var.master_username

  # If the RDS Cluster is being restored from a snapshot, the password entered by the user is ignored.
  master_password = var.snapshot_identifier == null ? var.master_password : null

  preferred_maintenance_window = var.preferred_maintenance_window
  preferred_backup_window      = var.preferred_backup_window
  backup_retention_period      = var.backup_retention_period

  # Due to a bug in Terraform, there is no way to disable the final snapshot in Aurora, so we always create one (which
  # is probably a safe default anyway, but a bit annoying for testing). For more info, see:
  # https://github.com/hashicorp/terraform/issues/6786
  final_snapshot_identifier = "${var.name}-final-snapshot"

  snapshot_identifier = var.snapshot_identifier

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  apply_immediately                   = var.apply_immediately
  storage_encrypted                   = var.storage_encrypted
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  tags = var.custom_tags
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

data "template_file" "auto_created_monitoring_role_arn" {
  template = var.monitoring_interval > 0 ? element(concat(aws_iam_role.enhanced_monitoring_role.*.arn, [""]), 0) : ""
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count = var.instance_count * (var.engine_mode == "serverless" ? 0 : 1)

  identifier = "${var.name}-${count.index}"
  cluster_identifier = element(
    concat(
      aws_rds_cluster.cluster_with_encryption_serverless.*.id,
      aws_rds_cluster.cluster_with_encryption_provisioned.*.id,
      aws_rds_cluster.cluster_without_encryption.*.id,
    ),
    0,
  )
  instance_class = var.instance_type

  engine         = var.engine
  engine_version = var.engine_version

  # These DBs instances are not publicly accessible. They should live in a private subnet and only be accessible from
  # specific apps.
  publicly_accessible = var.publicly_accessible

  db_subnet_group_name    = aws_db_subnet_group.cluster.name
  db_parameter_group_name = var.db_instance_parameter_group_name

  tags = var.custom_tags

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn != null ? var.monitoring_role_arn : data.template_file.auto_created_monitoring_role_arn.rendered

  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_kms_key_id

  # Without this line, I consistently receive the following error: aws_rds_cluster.cluster_without_encryption: Error
  # modifying DB Instance xxx: DBInstanceNotFound: DBInstance not found: xxx. However, I am not 100% sure this resolves
  # the issue.
  depends_on = [
    aws_rds_cluster.cluster_with_encryption_serverless,
    aws_rds_cluster.cluster_with_encryption_provisioned,
    aws_rds_cluster.cluster_without_encryption,
  ]
}

# ------------------------------------------------------------------------------
# CREATE THE SUBNET GROUP THAT SPECIFIES IN WHICH SUBNETS TO DEPLOY THE DB INSTANCES
# ------------------------------------------------------------------------------

resource "aws_db_subnet_group" "cluster" {
  name        = var.name
  description = "Subnet group for the ${var.name} DB"
  subnet_ids  = var.subnet_ids
  tags = merge(
    {
      "Name" = "The subnet group for the ${var.name} DB"
    },
    var.custom_tags,
  )
}

# ------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT CONTROLS WHAT TRAFFIC CAN CONNECT TO THE DB
# ------------------------------------------------------------------------------

resource "aws_security_group" "cluster" {
  name        = var.name
  description = "Security group for the ${var.name} DB"
  vpc_id      = var.vpc_id
  tags        = var.custom_tags
}

resource "aws_security_group_rule" "allow_connections_from_cidr_blocks" {
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
