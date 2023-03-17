# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SNS NOTIFICATIONS TO SLACK VIA LAMBDA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
# CREATE THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_function" "sns_to_slack" {
  count = var.create_resources ? 1 : 0

  function_name = var.lambda_function_name
  description   = "Forward SNS notifications to Slack"

  filename         = data.archive_file.lambda_payload.output_path
  source_code_hash = data.archive_file.lambda_payload.output_base64sha256

  handler = "alerts.handler"
  runtime = "python3.7"

  timeout     = 300
  memory_size = 128

  role = var.create_resources ? aws_iam_role.sns_to_slack[0].arn : null

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ZIP UP THE LAMBDA FUNCTION SOURCE CODE
# ---------------------------------------------------------------------------------------------------------------------

data "archive_file" "lambda_payload" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/lambda.zip"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM ROLE FOR THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "sns_to_slack" {
  count = var.create_resources ? 1 : 0

  name               = var.lambda_function_name
  assume_role_policy = data.aws_iam_policy_document.sns_to_slack.json
}

data "aws_iam_policy_document" "sns_to_slack" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GIVE THE LAMBDA FUNCTION PERMISSIONS TO LOG TO CLOUDWATCH
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "logging_for_lambda" {
  count = var.create_resources ? 1 : 0

  name   = "logging-for-lambda"
  role   = var.create_resources ? aws_iam_role.sns_to_slack[0].id : null
  policy = data.aws_iam_policy_document.logging_for_lambda.json
}

data "aws_iam_policy_document" "logging_for_lambda" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CONNECT THE LAMBDA FUNCTION TO SNS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "sns_to_slack" {
  count = var.create_resources ? 1 : 0

  provider  = aws
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = var.create_resources ? aws_lambda_function.sns_to_slack[0].arn : null
}

resource "aws_lambda_permission" "allow_sns" {
  count = var.create_resources ? 1 : 0

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = var.create_resources ? aws_lambda_function.sns_to_slack[0].arn : null
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}
