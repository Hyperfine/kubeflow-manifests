# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A LAMBDA FUNCTION THAT MAKES HTTP REQUESTS
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
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

module "lambda_function" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-lambda//modules/lambda?ref=v0.13.1"

  name        = var.name
  description = "Executing some requests to the internet"

  # Notice how the source_path is set to python/build, which doesn't initially exist. That's because you need to run
  # the build process for the code before deploying it with Terraform. See README.md for instructions.
  source_path = "${path.module}/python/build"
  runtime     = "python3.8"

  handler = "src/index.handler"
  tags = {
    Name = var.name
  }

  # configure the PYTHONPATH environment variable so it knows where to find dependencies
  # (https://docs.python.org/2/using/cmdline.html#envvar-PYTHONPATH).
  environment_variables = {
    PYTHONPATH = "/var/task/dependencies"
  }

  timeout     = 30
  memory_size = 128
}

resource "aws_sns_topic" "failure_topic" {
  name = var.sns_topic_name
}

module "lambda_alarm" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/alarms/lambda-alarms?ref=v1.0.8"
  source = "../../modules/alarms/lambda-alarms/"

  function_name        = module.lambda_function.function_name
  alarm_sns_topic_arns = [aws_sns_topic.failure_topic.arn]
}
