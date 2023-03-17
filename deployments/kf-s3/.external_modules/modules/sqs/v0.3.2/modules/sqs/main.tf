# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN AMAZON SQS QUEUE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM RUNTIME REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE QUEUE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sqs_queue" "queue" {
  # FIFO queues require .fifo as a suffix on the name: http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html
  name       = "${var.name}${var.fifo_queue ? ".fifo" : ""}"
  fifo_queue = var.fifo_queue

  redrive_policy = join("", data.template_file.redrive_policy.*.rendered)

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  max_message_size            = var.max_message_size
  content_based_deduplication = var.content_based_deduplication

  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds

  tags = var.custom_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A DEAD LETTER QUEUE AND POLICY IF VAR.DEAD_LETTER_QUEUE IS TRUE
# The dead letter queue is used for messages that cannot be processed successfully.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sqs_queue" "dead_letter_queue" {
  count = var.dead_letter_queue ? 1 : 0

  # FIFO queues require .fifo as a suffix on the name: http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html
  name       = "${var.name}-dead-letter${var.fifo_queue ? ".fifo" : ""}"
  fifo_queue = var.fifo_queue

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  max_message_size            = var.max_message_size
  content_based_deduplication = var.content_based_deduplication

  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds

  tags = var.custom_tags
}

data "template_file" "redrive_policy" {
  count = var.dead_letter_queue ? 1 : 0

  template = <<EOF
{"deadLetterTargetArn": "${aws_sqs_queue.dead_letter_queue[0].arn}", "maxReceiveCount": ${var.max_receive_count}}
EOF

}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE QUEUE POLICIES
# These policies only allow requests to the queues from the IP addresses in var.allowed_cidr_blocks and from the
# current VPC. Note that additional permissions, such as allowing a specific user or IAM role to access this queue, can
# be added separately via standard IAM policies.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "limit_queue_access_by_ip_address" {
  statement {
    effect = "Allow"

    actions = ["sqs:*"]

    principals {
      identifiers = ["*"]

      type = "AWS"
    }

    resources = [aws_sqs_queue.queue.arn]

    condition {
      test = "IpAddress"
      variable = "aws:SourceIp"

      # WARNING: This policy will allow unauthenticated traffic from the IP range in var.allowed_cidr_blocks
      values = var.allowed_cidr_blocks
    }
  }
}

data "aws_iam_policy_document" "limit_dead_letter_queue_access_by_ip_address" {
  count = var.dead_letter_queue ? 1 : 0

  statement {
    effect = "Allow"

    actions = ["sqs:*"]

    principals {
      identifiers = ["*"]

      type = "AWS"
    }

    resources = [aws_sqs_queue.dead_letter_queue[0].arn]

    condition {
      test = "IpAddress"
      variable = "aws:SourceIp"

      # WARNING: This policy will allow unauthenticated traffic from the IP range in var.allowed_cidr_blocks
      values = var.allowed_cidr_blocks
    }
  }
}

resource "aws_sqs_queue_policy" "limit_queue_access_by_ip_address" {
  count = var.apply_ip_queue_policy ? 1 : 0

  policy = data.aws_iam_policy_document.limit_queue_access_by_ip_address.json
  queue_url = aws_sqs_queue.queue.id
}

resource "aws_sqs_queue_policy" "limit_dead_letter_queue_access_by_ip_address" {
  count = var.dead_letter_queue && var.apply_ip_queue_policy ? 1 : 0

  policy = data.aws_iam_policy_document.limit_dead_letter_queue_access_by_ip_address[0].json
  queue_url = aws_sqs_queue.dead_letter_queue[0].id
}
