terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.70.1"
    }
  }
}

resource "aws_lambda_event_source_mapping" "connection" {
  event_source_arn = var.sqs_arn
  function_name    = var.lambda_arn

  batch_size = var.batch_size
}
