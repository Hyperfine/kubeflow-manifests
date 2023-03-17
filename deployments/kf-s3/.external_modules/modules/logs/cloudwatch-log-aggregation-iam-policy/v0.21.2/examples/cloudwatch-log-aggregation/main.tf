# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN EC2 INSTANCE THAT SENDS ITS LOGS TO CLOUDWATCH
# This is an example of how to launch an EC2 Instance configured to send everything in syslog to CloudWatch Logs.
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
# The AMI we run on this instance has the CloudWatch logs agent installed, which sends everything in syslog to
# CloudWatch. The AMI is built using the packer template under packer/build.json. We run a User Data script in this
# instance that logs some test data to syslog so you can see it flow all the way to CloudWatch.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "example" {
  ami                  = var.ami
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.example.name
  user_data            = data.template_file.user_data.rendered
  tags = {
    Name = var.name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE USER DATA SCRIPT
# This script runs when the EC2 Instance first boots. It starts the CloudWatch logs agent and logs some text to syslog
# so you can see it flow all the way to CloudWatch.
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")

  vars = {
    text_to_log    = var.text_to_log
    log_group_name = "${var.name}-logs"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM ROLE
# We can attach IAM policies to this role to give the EC2 Instance various IAM permissions.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "example" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json

  # Workaround for a bug where Terraform sometimes doesn't wait long enough for the IAM role to propagate.
  # https://github.com/hashicorp/terraform/issues/2660
  provisioner "local-exec" {
    command = "echo 'Sleeping for 30 seconds to work around IAM Instance Profile propagation bug in Terraform' && sleep 30"
  }
}

# To assign an IAM Role to an EC2 Instance, we actually need to assign the "IAM Instance Profile"
resource "aws_iam_instance_profile" "example" {
  name = var.name
  role = aws_iam_role.example.name

  # Workaround for a bug where Terraform sometimes doesn't wait long enough for the IAM instance profile to propagate.
  # https://github.com/hashicorp/terraform/issues/4306
  provisioner "local-exec" {
    command = "echo 'Sleeping for 30 seconds to work around IAM Instance Profile propagation bug in Terraform' && sleep 30"
  }
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ------------------------------------------------------------------------------
# ADD IAM POLICY THAT ALLOWS CLOUDWATCH LOG AGGREGATION
# ------------------------------------------------------------------------------

module "cloudwatch_log_aggregation" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/cloudwatch-log-aggregation-iam-policy?ref=v1.0.8"
  source      = "../../modules/logs/cloudwatch-log-aggregation-iam-policy"
  name_prefix = var.name
}

resource "aws_iam_policy_attachment" "attach_cloudwatch_log_aggregation_policy" {
  name       = "attach-cloudwatch-log-aggregation-policy"
  roles      = [aws_iam_role.example.id]
  policy_arn = module.cloudwatch_log_aggregation.cloudwatch_log_aggregation_policy_arn
}
