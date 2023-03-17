# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN ECS CLUSTER AND ECS SERVICE AND ADD CLOUDWATCH ALARMS TO THEM
# This is an example of how to deploy an EC2 Container Service (ECS) Cluster, run an a Docker container on it as an
# ECS Service, and attach alarms to it that go off if the CPU usage or memory usage get too high.
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
# CREATE THE ECS CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "ecs_cluster" {
  source = "git::git@github.com:gruntwork-io/module-ecs.git//modules/ecs-cluster?ref=v0.14.0"

  cluster_name     = var.cluster_name
  cluster_min_size = 2
  cluster_max_size = 2

  cluster_instance_ami       = var.cluster_instance_ami
  cluster_instance_type      = "t2.micro"
  cluster_instance_user_data = data.template_file.user_data.rendered

  # For this example, we allow no SSH connectivity
  cluster_instance_keypair_name    = null
  allow_ssh_from_security_group_id = null
  allow_ssh                        = false

  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.subnet_ids
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE USER DATA SCRIPT THAT WILL RUN ON EACH INSTANCE IN THE ECS CLUSTER
# This script will configure each instance so it registers in the right ECS cluster.
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")

  vars = {
    ecs_cluster_name = var.cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ECS TASK TO RUN MY DOCKER CONTAINER
# For this example, we just run the example training/webapp Docker container
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ECS SERVICE TO RUN MY ECS TASK
# ---------------------------------------------------------------------------------------------------------------------

module "ecs_service" {
  source = "git::git@github.com:gruntwork-io/module-ecs.git//modules/ecs-service?ref=v0.14.0"

  service_name     = var.service_name
  environment_name = var.environment_name
  ecs_cluster_arn  = module.ecs_cluster.ecs_cluster_arn

  ecs_task_container_definitions = <<EOF
[
  {
    "name": "${var.service_name}",
    "image": "training/webapp",
    "cpu": 1024,
    "memory": 512,
    "essential": true
  }
]
EOF


  desired_number_of_tasks = 1
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ALARMS FOR THE ECS CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "ecs_cluster_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/ecs-cluster-alarms?ref=v1.0.8"
  source = "../../modules/alarms/ecs-cluster-alarms"

  ecs_cluster_name = var.cluster_name
  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ------------------------------------------------------------------------------
# CREATE ALARMS FOR THE ECS SERVICE
# ------------------------------------------------------------------------------

module "ecs_service_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/ecs-service-alarms?ref=v1.0.8"
  source = "../../modules/alarms/ecs-service-alarms"

  ecs_service_name = var.service_name
  ecs_cluster_name = var.cluster_name
  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SNS TOPIC WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.cluster_name}-ecs-alarms"
}
