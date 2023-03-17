# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN ELASTIC LOAD BALANCER AND ENABLE ACCESS LOGGING FOR IT
# This is an example of how to deploy an Elastic Load Balancer (ELB) and to configure it to store its access log files
# in an S3 bucket.
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

# ------------------------------------------------------------------------------
# CREATE THE ELB
# ------------------------------------------------------------------------------

resource "aws_elb" "example" {
  name    = var.name
  subnets = var.subnet_ids

  access_logs {
    bucket        = module.elb_access_logs_bucket.s3_bucket_name
    interval      = 5
    bucket_prefix = var.name
  }

  # This adds a listener for incoming HTTP requests.
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 8080
    instance_protocol = "http"
  }

  # This should be inferrable by the fact that we reference a module var above, but due to a Terraform bug, we must
  # explicitly include the below line or we'll have a race condition per https://github.com/hashicorp/terraform/issues/10924.
  depends_on = [module.elb_access_logs_bucket]
}

# ------------------------------------------------------------------------------
# CREATE AN S3 BUCKET TO STORE ELB ACCESS LOGS
# ------------------------------------------------------------------------------

module "elb_access_logs_bucket" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/load-balancer-access-logs?ref=v1.0.8"
  source = "../../../modules/logs/load-balancer-access-logs"

  # Try to do some basic cleanup to get a valid S3 bucket name: the name must be lower case and can only contain
  # lowercase letters, numbers, and hyphens. For the full rules, see:
  # http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html#bucketnamingrules
  s3_bucket_name    = "elb-${lower(replace(var.name, "_", "-"))}-access-logs"
  s3_logging_prefix = var.name

  # DO NOT COPY THIS SETTING INTO YOUR APP!!!
  # It is only here so we can clean up the bucket automatically at test-time, even if there are files within it.
  force_destroy = true
  # DO NOT COPY THIS SETTING INTO YOUR APP!!!
}
