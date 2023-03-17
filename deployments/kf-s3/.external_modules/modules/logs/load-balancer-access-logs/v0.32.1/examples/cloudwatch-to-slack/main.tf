# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN EC2 INSTANCE, ADD CLOUDWATCH ALARMS TO IT, FORWARD THOSE ALARMS TO SLACK
# This is an example of how to deploy an EC2 Instance and attach alarms to the instance that go off if CPU, memory, or
# disk space usage are too high. Finally, it demonstrates forwarding those alarms to Slack.
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

  # Only this AWS Account ID may be operated on by this template
  allowed_account_ids = [var.aws_account_id]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "example" {
  count = var.create_resources ? 1 : 0

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = module.instance_type.recommended_instance_type
  vpc_security_group_ids = [aws_security_group.example[0].id]
  key_name               = var.keypair_name

  # We run an infinite loop in the user data script to ensure the server reaches 100% CPU and trigger alarms.
  user_data = <<EOF
#!/bin/bash
python3 -c "while True: print('hello world')" > /dev/null &
EOF

  # This EC2 Instance has a public IP and will be accessible directly from the public Internet
  associate_public_ip_address = true

  tags = {
    Name = var.name
  }
}

# Create a security group to control what goes in and out of the instance. To keep this example simple, we will allow
# all outbound access, and inbound SSH access from anywhere. In real-world usage, you should only allow SSH requests
# from trusted servers, such as a bastion host or VPN server.
resource "aws_security_group" "example" {
  count = var.create_resources ? 1 : 0

  name = var.name

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PICK AN INSTANCE TYPE
# We run automated tests against this example code in many regions, and some AZs in some regions don't have certain
# instance types. Therefore, we use this module to pick an instance type that's available in all AZs in the current
# region.
# ---------------------------------------------------------------------------------------------------------------------

module "instance_type" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-utilities.git//modules/instance-type?ref=v0.4.0"

  instance_types = ["t3.micro", "t2.micro"]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALARM FOR HIGH CPU USAGE
# ---------------------------------------------------------------------------------------------------------------------

module "ec2_high_cpu_usage_alarms" {
  create_resources = var.create_resources

  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/alarms/ec2-cpu-alarms?ref=v1.0.8"
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
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/alarms/sns-to-slack?ref=v1.0.8"
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
