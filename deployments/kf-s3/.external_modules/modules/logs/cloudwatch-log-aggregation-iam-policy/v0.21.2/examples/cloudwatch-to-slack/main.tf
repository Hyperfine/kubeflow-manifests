# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN EC2 INSTANCE, ADD CLOUDWATCH ALARMS TO IT, FORWARD THOSE ALARMS TO SLACK
# This is an example of how to deploy an EC2 Instance and attach alarms to the instance that go off if CPU, memory, or
# disk space usage are too high. Finally, it demonstrates forwarding those alarms to Slack.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  # Only this AWS Account ID may be operated on by this template
  allowed_account_ids = [var.aws_account_id]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "example" {
  count = var.create_resources ? 1 : 0

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  tags = {
    Name = var.name
  }
}

# Use an Ubuntu AMI for this example
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALARM FOR HIGH CPU USAGE
# ---------------------------------------------------------------------------------------------------------------------

module "ec2_high_cpu_usage_alarms" {
  create_resources = var.create_resources

  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/ec2-cpu-alarms?ref=v1.0.8"
  source               = "../../modules/alarms/ec2-cpu-alarms"
  instance_ids         = var.create_resources ? [aws_instance.example[0].id] : null
  instance_count       = 1
  alarm_sns_topic_arns = var.create_resources ? [aws_sns_topic.cloudwatch_alarms[0].arn] : null
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SNS TOPIC WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarms" {
  count = var.create_resources ? 1 : 0

  name = "${var.name}-ec2-alarms"
}

# ---------------------------------------------------------------------------------------------------------------------
# ENABLE CLOUDWATCH → SLACK INTEGRATION
# ---------------------------------------------------------------------------------------------------------------------

module "cloudwatch_to_slack" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/sns-to-slack?ref=v1.0.8"
  source = "../../modules/alarms/sns-to-slack"

  # A unique name for the lambda function
  lambda_function_name = var.name

  # The SNS Topic (in this case the same one CloudWatch alarms are pointed at) that should be forwarded to Slack
  sns_topic_arn = var.create_resources ? aws_sns_topic.cloudwatch_alarms[0].arn : null

  # This is configured in the `Incoming Webhooks` settings area of your Slack team.
  # The webhook will resemble https://hooks.slack.com/services/FOO/BAR/BAZ
  slack_webhook_url = var.slack_webhook_url

  # When set to false, the module will not actually do anything. This is a hack
  # because Terraform does not support conditional modules.
  create_resources = var.create_resources
}
