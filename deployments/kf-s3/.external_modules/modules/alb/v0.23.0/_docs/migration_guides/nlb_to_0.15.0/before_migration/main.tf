# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A STANDALONE NETWORK LOAD BALANCER (NLB)
# These templates show an example of how to deploy a standalone NLB using the deprecated module from an older version of
# this repository.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.14.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.14.x code.
  required_version = ">= 0.12.26"
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN NLB
# ---------------------------------------------------------------------------------------------------------------------

module "nlb" {
  # NOTE: This is using the last version that included our implementation of an NLB module. This module has been
  # removed in the next version, v0.15.0
  source = "git::git@github.com:gruntwork-io/terraform-aws-load-balancer.git//modules/nlb?ref=v0.14.2"

  aws_region = var.aws_region

  nlb_name         = var.nlb_name
  environment_name = var.environment_name
  is_internal_nlb  = false

  subnet_mapping = [
    {
      subnet_id     = element(tolist(data.aws_subnet_ids.default.ids), 0)
      allocation_id = aws_eip.example1.id
    },
    {
      subnet_id     = element(tolist(data.aws_subnet_ids.default.ids), 1)
      allocation_id = aws_eip.example2.id
    },
  ]

  subnet_mapping_size = 2

  enable_cross_zone_load_balancing = false
  ip_address_type                  = "ipv4"

  vpc_id                         = data.aws_vpc.default.id
  vpc_subnet_ids                 = data.aws_subnet_ids.default.ids
  enable_nlb_access_logs         = true
  nlb_access_logs_s3_bucket_name = module.nlb_access_logs_bucket.s3_bucket_name
}

resource "aws_eip" "example1" {
  vpc = true
}

resource "aws_eip" "example2" {
  vpc = true
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE S3 BUCKET USED TO STORE THE NLB'S LOGS
# ---------------------------------------------------------------------------------------------------------------------

# Create an S3 Bucket to store NLB access logs.
module "nlb_access_logs_bucket" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/logs/load-balancer-access-logs?ref=upgrade-terraform12"

  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = var.aws_region

  # Try to do some basic cleanup to get a valid S3 bucket name: the name must be lower case and can only contain
  # lowercase letters, numbers, and hyphens. For the full rules, see:
  # http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html#bucketnamingrules
  s3_bucket_name = "nlb-${lower(replace(var.nlb_name, "_", "-"))}-access-logs"

  s3_logging_prefix = var.nlb_name

  num_days_after_which_archive_log_data = var.num_days_after_which_archive_log_data
  num_days_after_which_delete_log_data  = var.num_days_after_which_delete_log_data

  ## DO NOT USE THIS SETTING IN PRODUCTION! ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
  # In a test environment, we want to destroy the S3 Bucket, even if data is there when we do so. But in production, the
  # default setting of preventing a non-empty S3 Bucket from being destroyed should be used. Therefore, this property can
  # be omitted in production use.
  force_destroy = var.force_destroy_access_logs_s3_bucket
  ## DO NOT USE THIS SETTING IN PRODUCTION! ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
}

# ---------------------------------------------------------------------------------------------------------------------
# LAUNCH SAMPLE EC2 INSTANCE
# Launch a sample EC2 Instance that will run a basic server that can be accessed via the NLB.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "example_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = var.example_server_keypair_name
  vpc_security_group_ids      = [aws_security_group.example_server.id]
  subnet_id                   = tolist(data.aws_subnet_ids.default.ids)[0]
  associate_public_ip_address = true
  user_data                   = data.template_file.user_data.rendered

  tags = {
    Name = "${var.nlb_name}-nlb-example-server"
  }
}

resource "aws_security_group" "example_server" {
  vpc_id = data.aws_vpc.default.id

  # Outbound Everything
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.nlb_name}-nlb-example-server-sg"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# REGISTER SAMPLE SERVER AS A BACKEND FOR NLB
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb_listener" "example_server" {
  load_balancer_arn = module.nlb.nlb_arn
  port              = var.server_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_server.arn
  }
}

resource "aws_lb_target_group" "example_server" {
  name     = "${var.nlb_name}-nlb-ex-server-tg"
  port     = 8080
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_target_group_attachment" "example_server" {
  target_group_arn = aws_lb_target_group.example_server.id
  target_id        = aws_instance.example_server.id
  port             = 8080
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE USER DATA SCRIPT TO RUN WHEN EACH EC2 INSTANCE BOOTS
# This script runs a simple web server on each instance that returns the specified text
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data" {
  template = <<EOF
#!/bin/bash
echo "${var.server_text}" > index.html
nohup busybox httpd -f -p "${var.server_port}" 2>&1 | logger &
EOF

}

# ---------------------------------------------------------------------------------------------------------------------
# LOOKUP EXISTING RESOURCES TO USE
# - Default VPC
# - Latest Ubuntu AMI
# ---------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

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
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
}
