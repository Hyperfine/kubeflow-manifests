# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN AMAZON SNS TOPIC
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM RUNTIME REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE TOPIC
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "topic" {
  name         = var.name
  display_name = format("%.10s", var.display_name)
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE TOPIC POLICIES
# These policies only allow requests to the queues from the IP addresses in var.allowed_cidr_blocks and from the
# current VPC. Note that additional permissions, such as allowing a specific user or IAM role to access this queue, can
# be added separately via standard IAM policies.
# ---------------------------------------------------------------------------------------------------------------------

# Which users other than the topic owner (creator) can publish to this topic
data "aws_iam_policy_document" "topic_policy_publishers_only" {
  count = length(var.allow_publish_accounts) > 0 && length(var.allow_subscribe_accounts) == 0 ? 1 : 0
  statement {
    sid    = "AllowPublishers"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.topic.arn,
    ]

    principals {
      type        = "AWS"
      identifiers = var.allow_publish_accounts
    }
  }
}

data "aws_iam_policy_document" "topic_policy_subscribers_only" {
  count = length(var.allow_publish_accounts) == 0 && length(var.allow_subscribe_accounts) > 0 ? 1 : 0
  statement {
    sid    = "AllowSubscribers"
    effect = "Allow"

    actions   = ["sns:Subscribe"]
    resources = [aws_sns_topic.topic.arn]

    principals {
      type        = "AWS"
      identifiers = var.allow_subscribe_accounts
    }

    condition {
      test     = "StringEquals"
      values   = var.allow_subscribe_protocols
      variable = "SNS:Protocol"
    }
  }
}

data "aws_iam_policy_document" "topic_policy_publishers_and_subscribers" {
  count = length(var.allow_publish_accounts) > 0 && length(var.allow_subscribe_accounts) > 0 ? 1 : 0
  statement {
    sid    = "AllowPublishers"
    effect = "Allow"

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.topic.arn]

    principals {
      type        = "AWS"
      identifiers = var.allow_publish_accounts
    }
  }

  statement {
    sid    = "AllowSubscribers"
    effect = "Allow"

    actions   = ["sns:Subscribe"]
    resources = [aws_sns_topic.topic.arn]

    principals {
      type        = "AWS"
      identifiers = var.allow_subscribe_accounts
    }

    condition {
      test     = "StringEquals"
      values   = var.allow_subscribe_protocols
      variable = "SNS:Protocol"
    }
  }
}

resource "aws_sns_topic_policy" "topic_policy" {
  count = length(var.allow_publish_accounts) > 0 || length(var.allow_subscribe_accounts) > 0 ? 1 : 0
  policy = element(
    concat(
      data.aws_iam_policy_document.topic_policy_publishers_only.*.json,
      data.aws_iam_policy_document.topic_policy_subscribers_only.*.json,
      data.aws_iam_policy_document.topic_policy_publishers_and_subscribers.*.json,
    ),
    0,
  )
  arn = aws_sns_topic.topic.arn
}
