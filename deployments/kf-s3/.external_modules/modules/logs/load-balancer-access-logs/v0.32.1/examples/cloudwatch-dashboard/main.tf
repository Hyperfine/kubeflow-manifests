# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A CLOUDWATCH DASHBOARD WITH WIDGETS
# This is an example of how to manage CloudWatch dashboards as code.
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
  allowed_account_ids = ["${var.aws_account_id}"]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SIMPLE TEXT WIDGET
# ---------------------------------------------------------------------------------------------------------------------

module "text_widget_1" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-text-widget?ref=v1.0.8"
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
  instance_type = module.instance_type.recommended_instance_type

  tags = {
    Name = "EC2-Instance-1"
  }
}

resource "aws_instance" "instance_2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = module.instance_type.recommended_instance_type

  tags = {
    Name = "EC2-Instance-2"
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
# CREATE A METRIC WIDGET TO DISPLAY CPU UTILIZATION OF SAMPLE INSTANCES
# ---------------------------------------------------------------------------------------------------------------------

module "metric_widget_1" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v1.0.8"
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
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/metrics/cloudwatch-dashboard?ref=v1.0.8"
  source = "../../modules/metrics/cloudwatch-dashboard"

  dashboards = {
    (var.name) = [
      module.text_widget_1.widget,
      module.metric_widget_1.widget,
    ]
  }
}
