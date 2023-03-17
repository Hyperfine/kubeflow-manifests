# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN ELASTICSEARCH CLUSTER AND ADD CLOUDWATCH ALARMS TO IT
# This is an example of how to create an Elasticsearch cluster and how to attach alarms to the cluster that go off if
# the CPU usage or heap usage gets too high, storage space gets too low, or the cluster goes into yellow or red status
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
# CREATE THE ELASTICSEARCH CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_elasticsearch_domain" "cluster" {
  domain_name           = var.cluster_name
  elasticsearch_version = "7.1"

  cluster_config {
    instance_type  = var.instance_type
    instance_count = var.instance_count
  }

  # EBS volumes are useful if your cluster nodes need more disk space than is available on the node itself. Note that
  # t2 nodes always require EBS volumes.
  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ALARMS FOR THE ELASTICSEARCH CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "elasticsearch_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/alarms/elasticsearch-alarms?ref=v1.0.8"
  source = "../../modules/alarms/elasticsearch-alarms"

  cluster_name   = aws_elasticsearch_domain.cluster.domain_name
  aws_account_id = var.aws_account_id
  instance_type  = var.instance_type
  instance_count = var.instance_count

  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE SNS TOPICS WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.cluster_name}-alarms"
}
