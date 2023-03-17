# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN EFS FILE SYSTEM
# This template creates an Amazon EFS file system to store files in the Amazon cloud. The file system grows and
# shrinks automatically with the files you put in, and you pay only for what you use. After creating the file system,
# you can read and write files using the NFSv4 protocol. Any number of EC2 instances can access the file system at the
# same time, even if they are running in multiple Availability Zones in a region.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 4.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  efs_security_group_name        = var.aws_efs_security_group_name == null ? var.name : var.aws_efs_security_group_name
  efs_security_group_description = var.aws_efs_security_group_description == null ? "Security group for the ${var.name} EFS file system" : var.aws_efs_security_group_description
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE EFS FILE SYSTEM
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_efs_file_system" "this" {
  creation_token = var.name

  encrypted  = var.storage_encrypted
  kms_key_id = var.kms_key_arn

  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps

  tags = merge(
    {
      "Name" = var.name
    }, var.custom_tags
  )

  dynamic "lifecycle_policy" {
    for_each = compact([var.transition_to_ia])
    content {
      transition_to_ia = lifecycle_policy.value
    }
  }
}

resource "aws_efs_mount_target" "this" {
  count           = length(var.subnet_ids) > 0 ? length(var.subnet_ids) : 0
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.this.id]
}

# ------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT CONTROLS WHAT TRAFFIC CAN CONNECT TO THE FILE SYSTEM
# ------------------------------------------------------------------------------

resource "aws_security_group" "this" {
  name        = local.efs_security_group_name
  description = local.efs_security_group_description
  vpc_id      = var.vpc_id
  tags        = var.custom_tags
}

resource "aws_security_group_rule" "allow_connections_from_cidr_blocks" {
  count             = signum(length(var.allow_connections_from_cidr_blocks))
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = var.allow_connections_from_cidr_blocks
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "allow_connections_from_security_group" {
  count                    = length(var.allow_connections_from_security_groups)
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = var.allow_connections_from_security_groups[count.index]
  security_group_id        = aws_security_group.this.id
}

# ------------------------------------------------------------------------------
# CREATE EFS ACCESS POINTS
# ------------------------------------------------------------------------------

resource "aws_efs_access_point" "this" {
  for_each = var.efs_access_points

  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid            = each.value.posix_user.uid
    gid            = each.value.posix_user.gid
    secondary_gids = each.value.posix_user.secondary_gids
  }

  root_directory {
    path = each.value.root_directory.path

    creation_info {
      owner_uid   = each.value.root_directory.owner_uid
      owner_gid   = each.value.root_directory.owner_gid
      permissions = each.value.root_directory.permissions
    }
  }

  tags = {
    Name = each.key
  }
}

# ------------------------------------------------------------------------------
# CREATE EFS ACCESS POLICY
# ------------------------------------------------------------------------------

locals {
  efs_endpoints_with_access_policy = [
    for name, options in var.efs_access_points : name
    if length(options.read_write_access_arns) + length(options.read_only_access_arns) + length(options.root_access_arns) > 0
  ]
  create_efs_policy = var.enforce_in_transit_encryption || var.allow_access_via_mount_target || length(local.efs_endpoints_with_access_policy) > 0
}

resource "aws_efs_file_system_policy" "this" {
  count          = local.create_efs_policy ? 1 : 0
  file_system_id = aws_efs_file_system.this.id
  policy         = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  dynamic "statement" {
    for_each = var.enforce_in_transit_encryption ? ["enabled"] : []

    content {
      sid       = "Enforce in-transit encryption for all clients"
      effect    = "Deny"
      actions   = ["*"]
      resources = [aws_efs_file_system.this.arn]

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      condition {
        test     = "Bool"
        values   = ["false"]
        variable = "aws:SecureTransport"
      }
    }
  }

  dynamic "statement" {
    for_each = var.allow_access_via_mount_target ? ["enabled"] : []

    content {
      sid    = "Allow access via mount targets"
      effect = "Allow"
      actions = [
        "elasticfilesystem:ClientRootAccess",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientMount"
      ]
      resources = [aws_efs_file_system.this.arn]

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      condition {
        test     = "Bool"
        values   = ["true"]
        variable = "elasticfilesystem:AccessedViaMountTarget"
      }
    }
  }

  dynamic "statement" {
    for_each = { for name, options in var.efs_access_points :
      name => options
      if length(options.root_access_arns) > 0
    }

    content {
      sid    = "Allow root access to the ${statement.key} EFS access point"
      effect = "Allow"
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess",
      ]
      resources = [aws_efs_file_system.this.arn]

      principals {
        type        = "AWS"
        identifiers = statement.value.root_access_arns
      }

      condition {
        test     = "StringEquals"
        values   = [aws_efs_access_point.this[statement.key].arn]
        variable = "elasticfilesystem:AccessPointArn"
      }
    }
  }

  dynamic "statement" {
    for_each = { for name, options in var.efs_access_points :
      name => options
      if length(options.read_write_access_arns) > 0
    }

    content {
      sid    = "Allow read and write access to the ${statement.key} EFS access point"
      effect = "Allow"
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
      ]
      resources = [aws_efs_file_system.this.arn]

      principals {
        type        = "AWS"
        identifiers = statement.value.read_write_access_arns
      }

      condition {
        test     = "StringEquals"
        values   = [aws_efs_access_point.this[statement.key].arn]
        variable = "elasticfilesystem:AccessPointArn"
      }
    }
  }

  dynamic "statement" {
    for_each = { for name, options in var.efs_access_points :
      name => options
      if length(options.read_only_access_arns) > 0
    }

    content {
      sid    = "Allow read only access to the ${statement.key} EFS access point"
      effect = "Allow"
      actions = [
        "elasticfilesystem:ClientMount",
      ]
      resources = [aws_efs_file_system.this.arn]

      principals {
        type        = "AWS"
        identifiers = statement.value.read_only_access_arns
      }

      condition {
        test     = "StringEquals"
        values   = [aws_efs_access_point.this[statement.key].arn]
        variable = "elasticfilesystem:AccessPointArn"
      }
    }
  }
}
