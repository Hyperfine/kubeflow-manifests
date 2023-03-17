# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A CLOUDWATCH DASHBOARD WITH WIDGETS
# This is an example of how to manage CloudWatch dashboards as code.
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
  allowed_account_ids = ["${var.aws_account_id}"]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SIMPLE TEXT WIDGET
# ---------------------------------------------------------------------------------------------------------------------

module "text_widget_1" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-text-widget?ref=v1.0.8"
  source = "../../modules/metrics/cloudwatch-dashboard-text-widget"

  markdown = "A text widget"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE TWO SAMPLE INSTANCES TO MONITOR ON OUR DASHBOARD
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "instance_1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "EC2-Instance-1"
  }
}

resource "aws_instance" "instance_2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "EC2-Instance-2"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A METRIC WIDGET TO DISPLAY CPU UTILIZATION OF SAMPLE INSTANCES
# ---------------------------------------------------------------------------------------------------------------------

module "metric_widget_1" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v1.0.8"
  source = "../../modules/metrics/cloudwatch-dashboard-metric-widget"

  metrics = [
    [
      "AWS/EC2",
      "CPUUtilization",
      "InstanceId",
      aws_instance.instance_1.id,
    ],
    [
      "AWS/EC2",
      "CPUUtilization",
      "InstanceId",
      aws_instance.instance_2.id,
    ],
  ]

  stacked = true
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE DASHBOARD
# ---------------------------------------------------------------------------------------------------------------------

module "dashboard" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard?ref=v1.0.8"
  source = "../../modules/metrics/cloudwatch-dashboard"

  dashboards = {
    (var.name) = [
      module.text_widget_1.widget,
      module.metric_widget_1.widget,
    ]
  }
}
