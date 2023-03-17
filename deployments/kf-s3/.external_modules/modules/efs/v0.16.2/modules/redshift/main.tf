# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A REDSHIFT CLUSTER
# This template creates an Amazon Redshift cluster. The cluster is managed by AWS and automatically handles standby 
# failover, read replicas, backups, patching, and encryption.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  cluster_subnet_group_name        = var.cluster_subnet_group_name == null ? var.name : var.cluster_subnet_group_name
  cluster_subnet_group_description = var.cluster_subnet_group_description == null ? "Subnet group for the ${var.name} DB" : var.cluster_subnet_group_description
  parameter_group_name             = var.parameter_group_name == null ? "default.redshift-1.0" : var.parameter_group_name

  final_snapshot_name           = var.final_snapshot_name == null ? "${var.name}-final-snapshot" : var.final_snapshot_name
  db_security_group_name        = var.aws_db_security_group_name == null ? var.name : var.aws_db_security_group_name
  db_security_group_description = var.aws_db_security_group_description == null ? "Security group for the ${var.name} DB" : var.aws_db_security_group_description
}

# ------------------------------------------------------------------------------
# CREATE THE SUBNET GROUP THAT SPECIFIES IN WHICH SUBNETS TO DEPLOY THE DB INSTANCES
# ------------------------------------------------------------------------------

resource "aws_redshift_subnet_group" "db" {
  count = var.create_subnet_group ? 1 : 0

  name        = local.cluster_subnet_group_name
  description = local.cluster_subnet_group_name
  subnet_ids  = var.subnet_ids
  tags = merge(
    { Name = "The subnet group for the ${var.name} DB" },
    var.custom_tags,
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE REDSHIFT CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_redshift_cluster" "cluster" {
  cluster_identifier = var.name
  database_name      = var.db_name
  node_type          = var.instance_type
  number_of_nodes    = var.number_of_nodes

  encrypted  = var.storage_encrypted
  kms_key_id = var.kms_key_arn

  port = var.port

  # By default databases should not be publicly accessible.
  # Make publicly_accessible configurable so that end users can choose whether or not their db's are accessible to the open Internet.
  publicly_accessible = var.publicly_accessible

  vpc_security_group_ids       = [aws_security_group.db.id]
  cluster_subnet_group_name    = local.cluster_subnet_group_name
  cluster_parameter_group_name = local.parameter_group_name

  master_username = var.master_username
  master_password = var.master_password

  automated_snapshot_retention_period = var.backup_retention_period
  preferred_maintenance_window        = var.maintenance_window
  final_snapshot_identifier           = local.final_snapshot_name
  skip_final_snapshot                 = var.skip_final_snapshot
  snapshot_identifier                 = var.snapshot_identifier

  allow_version_upgrade = var.auto_minor_version_upgrade

  tags = var.custom_tags

  # We depend on aws_db_subnet_group, but due to the need to name things dynamically and using local vars, our code
  # doesn't reflect that dependency, so we have to call it out explicitly
  depends_on = [aws_redshift_subnet_group.db]
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
