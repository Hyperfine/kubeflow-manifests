# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN AMAZON SNS TOPIC
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM RUNTIME REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE TOPIC
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "topic" {
  count             = var.create_resources ? 1 : 0
  name              = var.name
  display_name      = format("%.100s", var.display_name)
  tags              = var.tags
  kms_master_key_id = var.kms_master_key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE TOPIC POLICIES
# These policies restrict SNS subscribe and publish actions to those users/services as determined from the var.allow_publish_accounts, var.allow_publish_services, and var.allow_subscribe_accounts variables.
# Note that additional permissions, such as allowing a specific user or IAM role to access this topic, can
# be added separately via standard IAM policies.
# ---------------------------------------------------------------------------------------------------------------------

# Using local variable to determine whether or not to create sns topic policy. If the subsribers and publishers variables are left empty, then there is no need to create IAM policy document resources.
locals {
  create_policy = var.create_resources && length(concat(var.allow_subscribe_accounts, var.allow_publish_accounts, var.allow_publish_services)) > 0 ? true : false
}

data "aws_iam_policy_document" "topic_policy" {
  count = local.create_policy ? 1 : 0

  # add services if needed
  dynamic "statement" {
    for_each = length(var.allow_publish_services) > 0 ? list("1") : []

    content {
      sid     = "AllowServicePublishers"
      effect  = "Allow"
      actions = ["sns:Publish"]

      resources = [join("", aws_sns_topic.topic.*.arn)]

      principals {
        type        = "Service"
        identifiers = var.allow_publish_services
      }
    }

  }

  # add publisher IAM arns if needed
  dynamic "statement" {
    for_each = length(var.allow_publish_accounts) > 0 ? list("1") : []

    content {
      sid     = "AllowPublishers"
      effect  = "Allow"
      actions = ["sns:Publish"]

      resources = [join("", aws_sns_topic.topic.*.arn)]

      principals {
        type        = "AWS"
        identifiers = var.allow_publish_accounts
      }
    }
  }

  # add subsribers if needed
  dynamic "statement" {
    for_each = length(var.allow_subscribe_accounts) > 0 ? list("1") : []

    content {

      sid    = "AllowSubscribers"
      effect = "Allow"

      actions   = ["sns:Subscribe"]
      resources = [join("", aws_sns_topic.topic.*.arn)]

      principals {
        type        = "AWS"
        identifiers = var.allow_subscribe_accounts
      }

      condition {
        test     = "StringEquals"
        variable = "SNS:Protocol"
        values   = var.allow_subscribe_protocols
      }
    }
  }

}

resource "aws_sns_topic_policy" "topic_policy" {
  count  = local.create_policy ? 1 : 0
  policy = join("", data.aws_iam_policy_document.topic_policy.*.json)

  arn = join("", aws_sns_topic.topic.*.arn)
}
