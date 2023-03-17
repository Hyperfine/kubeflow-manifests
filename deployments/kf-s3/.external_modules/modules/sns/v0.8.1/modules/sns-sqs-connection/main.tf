terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.70.1, < 4.0"
    }
  }
}

# Note: the Region should match the SNS region 

resource "aws_sns_topic_subscription" "sqs_target" {
  topic_arn = var.sns_topic_arn
  protocol  = "sqs"
  endpoint  = var.sqs_arn
}
resource "aws_sqs_queue_policy" "connect" {
  queue_url = var.sqs_queue_url

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${var.sqs_arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${var.sns_topic_arn}"
        }
      }
    }
  ]
}
POLICY
}