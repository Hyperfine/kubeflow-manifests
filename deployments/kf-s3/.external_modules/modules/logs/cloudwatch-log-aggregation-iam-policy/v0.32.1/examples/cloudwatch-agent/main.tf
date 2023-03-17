# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN EC2 INSTANCE THAT SENDS ITS LOGS TO CLOUDWATCH
# This is an example of how to launch an EC2 Instance configured to send everything in syslog to CloudWatch Logs.
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
# CREATE THE EC2 INSTANCE
# The AMI we run on this instance has the CloudWatch logs agent installed, which sends everything in syslog to
# CloudWatch. The AMI is built using the packer template under packer/build.json. We run a User Data script in this
# instance that logs some test data to syslog so you can see it flow all the way to CloudWatch.
# ---------------------------------------------------------------------------------------------------------------------

# Not every region and Availability Zone in AWS supports both of these, so we use the `instance-type` module to help
# us choose the one that is supported with the configured AWS provider.
module "instance_types" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-utilities.git//modules/instance-type?ref=v0.4.0"

  instance_types = ["t2.micro", "t3.micro"]
}

module "example_instance_with_logs_and_metrics" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-server//modules/single-server?ref=v0.11.0"

  name          = "${var.name}-all"
  ami           = var.ami
  instance_type = module.instance_types.recommended_instance_type
  keypair_name  = var.key_name
  vpc_id        = data.aws_vpc.default.id
  subnet_id     = tolist(data.aws_subnet_ids.default.ids)[0]

  # The AMI we run for this example requires at least 20GB of space
  root_volume_size = 30

  # This script runs when the EC2 Instance first boots. It starts the CloudWatch logs agent and logs some text to syslog
  # so you can see it flow all the way to CloudWatch.
  user_data = templatefile(
    "${path.module}/user-data/user-data.sh",
    {
      text_to_log          = var.text_to_log
      log_group_name       = local.log_group_name
      disable_cpu_metrics  = false
      disable_mem_metrics  = false
      disable_disk_metrics = false
    },
  )

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_ssh_from_cidr_list   = ["0.0.0.0/0"]
  allow_all_outbound_traffic = true
  attach_eip                 = false
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD IAM POLICY THAT ALLOWS CLOUDWATCH LOG AGGREGATION
# ---------------------------------------------------------------------------------------------------------------------

module "cloudwatch_log_aggregation" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/cloudwatch-log-aggregation-iam-policy?ref=v1.0.8"
  source      = "../../modules/logs/cloudwatch-log-aggregation-iam-policy"
  name_prefix = var.name
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_log_aggregation_policy" {
  for_each   = local.all_iam_roles
  role       = each.key
  policy_arn = module.cloudwatch_log_aggregation.cloudwatch_log_aggregation_policy_arn
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD IAM POLICY THAT ALLOWS READING AND WRITING CLOUDWATCH METRICS
# ---------------------------------------------------------------------------------------------------------------------

module "cloudwatch_metrics" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-custom-metrics-iam-policy?ref=v1.0.8"
  source      = "../../modules/metrics/cloudwatch-custom-metrics-iam-policy"
  name_prefix = var.name
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_metrics_policy" {
  for_each   = local.all_iam_roles
  role       = each.key
  policy_arn = module.cloudwatch_metrics.cloudwatch_metrics_policy_arn
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE LOG GROUP FOR AGGREGATION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "server_logs" {
  name = local.log_group_name
}

locals {
  log_group_name = "${var.name}-logs"
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD ADDITIONAL INSTANCES WITH VARIOUS METRIC CONFIGURATIONS
# ---------------------------------------------------------------------------------------------------------------------

module "example_instance_no_metrics" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-server//modules/single-server?ref=v0.11.0"

  name          = "${var.name}-nometrics"
  ami           = var.ami
  instance_type = module.instance_types.recommended_instance_type
  keypair_name  = var.key_name
  vpc_id        = data.aws_vpc.default.id
  subnet_id     = tolist(data.aws_subnet_ids.default.ids)[0]

  # The AMI we run for this example requires at least 20GB of space
  root_volume_size = 30

  # This script runs when the EC2 Instance first boots. It starts the CloudWatch logs agent and logs some text to syslog
  # so you can see it flow all the way to CloudWatch.
  user_data = templatefile(
    "${path.module}/user-data/user-data.sh",
    {
      text_to_log          = var.text_to_log
      log_group_name       = local.log_group_name
      disable_cpu_metrics  = true
      disable_mem_metrics  = true
      disable_disk_metrics = true
    },
  )

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_ssh_from_cidr_list   = ["0.0.0.0/0"]
  allow_all_outbound_traffic = true
  attach_eip                 = false
}

module "example_instance_no_cpu_metrics" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-server//modules/single-server?ref=v0.11.0"

  name          = "${var.name}-nocpumetrics"
  ami           = var.ami
  instance_type = module.instance_types.recommended_instance_type
  keypair_name  = var.key_name
  vpc_id        = data.aws_vpc.default.id
  subnet_id     = tolist(data.aws_subnet_ids.default.ids)[0]

  # The AMI we run for this example requires at least 20GB of space
  root_volume_size = 30

  # This script runs when the EC2 Instance first boots. It starts the CloudWatch logs agent and logs some text to syslog
  # so you can see it flow all the way to CloudWatch.
  user_data = templatefile(
    "${path.module}/user-data/user-data.sh",
    {
      text_to_log          = var.text_to_log
      log_group_name       = local.log_group_name
      disable_cpu_metrics  = true
      disable_mem_metrics  = false
      disable_disk_metrics = false
    },
  )

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_ssh_from_cidr_list   = ["0.0.0.0/0"]
  allow_all_outbound_traffic = true
  attach_eip                 = false
}

module "example_instance_no_mem_metrics" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-server//modules/single-server?ref=v0.11.0"

  name          = "${var.name}-nomemmetrics"
  ami           = var.ami
  instance_type = module.instance_types.recommended_instance_type
  keypair_name  = var.key_name
  vpc_id        = data.aws_vpc.default.id
  subnet_id     = tolist(data.aws_subnet_ids.default.ids)[0]

  # The AMI we run for this example requires at least 20GB of space
  root_volume_size = 30

  # This script runs when the EC2 Instance first boots. It starts the CloudWatch logs agent and logs some text to syslog
  # so you can see it flow all the way to CloudWatch.
  user_data = templatefile(
    "${path.module}/user-data/user-data.sh",
    {
      text_to_log          = var.text_to_log
      log_group_name       = local.log_group_name
      disable_cpu_metrics  = false
      disable_mem_metrics  = true
      disable_disk_metrics = false
    },
  )

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_ssh_from_cidr_list   = ["0.0.0.0/0"]
  allow_all_outbound_traffic = true
  attach_eip                 = false
}

module "example_instance_no_disk_metrics" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-server//modules/single-server?ref=v0.11.0"

  name          = "${var.name}-nodiskmetrics"
  ami           = var.ami
  instance_type = module.instance_types.recommended_instance_type
  keypair_name  = var.key_name
  vpc_id        = data.aws_vpc.default.id
  subnet_id     = tolist(data.aws_subnet_ids.default.ids)[0]

  # The AMI we run for this example requires at least 20GB of space
  root_volume_size = 30

  # This script runs when the EC2 Instance first boots. It starts the CloudWatch logs agent and logs some text to syslog
  # so you can see it flow all the way to CloudWatch.
  user_data = templatefile(
    "${path.module}/user-data/user-data.sh",
    {
      text_to_log          = var.text_to_log
      log_group_name       = local.log_group_name
      disable_cpu_metrics  = false
      disable_mem_metrics  = false
      disable_disk_metrics = true
    },
  )

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_ssh_from_cidr_list   = ["0.0.0.0/0"]
  allow_all_outbound_traffic = true
  attach_eip                 = false
}

locals {
  all_iam_roles = toset([
    module.example_instance_with_logs_and_metrics.iam_role_name,
    module.example_instance_no_metrics.iam_role_name,
    module.example_instance_no_cpu_metrics.iam_role_name,
    module.example_instance_no_mem_metrics.iam_role_name,
    module.example_instance_no_disk_metrics.iam_role_name,
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# We lookup and use the Default VPC here to keep the example simple to deploy and test. In production, you will want to
# set up and configure a dedicated VPC for your infrastructure.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
