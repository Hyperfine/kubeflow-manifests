# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A STANDALONE APPLICATION LOAD BALANCER (ALB)
# These templates show an example of how to deploy a standalone ALB. In practice, you would usually define an ANB in
# conjunction with an ECS Cluster, ECS Service, and/or Auto Scaling Group.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALB
# ---------------------------------------------------------------------------------------------------------------------

module "alb" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-load-balancer.git//modules/alb?ref=v1.0.8"
  source = "../../modules/alb"

  aws_account_id = data.aws_caller_identity.current.id
  aws_region     = var.aws_region

  alb_name         = var.alb_name
  environment_name = var.environment_name
  is_internal_alb  = false

  http_listener_ports = [80]
  ssl_policy          = "ELBSecurityPolicy-TLS-1-1-2017-01"

  # This Security Groups are added to test a fix for a bug that raises duplicate errors
  # when multiple SGs and http listener ports are specified.
  # See https://github.com/gruntwork-io/module-load-balancer/pull/43
  allow_inbound_from_security_group_ids = [aws_security_group.sg1.id, aws_security_group.sg2.id]

  allow_inbound_from_security_group_ids_num = 2

  https_listener_ports_and_acm_ssl_certs = [
    {
      port            = 443
      tls_domain_name = "*.${var.route53_zone_name}"
    },
  ]

  https_listener_ports_and_acm_ssl_certs_num = 1

  vpc_id         = data.aws_vpc.default.id
  vpc_subnet_ids = data.aws_subnet_ids.default.ids
}

resource "aws_security_group" "sg1" {
  name   = "${var.alb_name}-sg-1"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "sg2" {
  name   = "${var.alb_name}-sg-2"
  vpc_id = data.aws_vpc.default.id
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
