# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A STANDALONE NETWORK LOAD BALANCER (NLB)
# These templates show an example of how to deploy a standalone NLB. In practice, you would usually define an ANB in
# conjunction with an ECS Cluster, ECS Service, and/or Auto Scaling Group.
# ---------------------------------------------------------------------------------------------------------------------

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
# CREATE AN NLB
# ---------------------------------------------------------------------------------------------------------------------

module "nlb" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-load-balancer.git//modules/nlb?ref=v1.0.0"
  source = "../../modules/nlb"

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

  tcp_listener_ports = [80, 8080]

  vpc_id         = data.aws_vpc.default.id
  vpc_subnet_ids = data.aws_subnet_ids.default.ids
}

resource "aws_eip" "example1" {
  vpc = true
}

resource "aws_eip" "example2" {
  vpc = true
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
