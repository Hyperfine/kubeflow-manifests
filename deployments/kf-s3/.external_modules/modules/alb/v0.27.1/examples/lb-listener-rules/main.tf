terraform {
  # This module is now only being tested with Terraform 1.0.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 1.0.x code.
  required_version = ">= 0.12.26"
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALB
# ---------------------------------------------------------------------------------------------------------------------

locals {
  alb_listener_port = 80
}

module "alb" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-load-balancer.git//modules/alb?ref=v1.0.8"
  source = "../../modules/alb"

  alb_name = var.alb_name

  // For testing, we are allowing ALL but for production, you should limit just for the servers you want to trust
  allow_inbound_from_cidr_blocks = ["0.0.0.0/0"]

  // For public, user-facing services (i.e., those accessible from the public Internet), this should be set to false.
  is_internal_alb = false

  http_listener_ports = [local.alb_listener_port]
  ssl_policy          = "ELBSecurityPolicy-TLS-1-1-2017-01"

  vpc_id         = data.aws_vpc.default.id
  vpc_subnet_ids = data.aws_subnet_ids.default.ids
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE LISTENER RULES FOR ALB
# ---------------------------------------------------------------------------------------------------------------------

module "lb_listener_rules" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-load-balancer.git//modules/lb-listener-rules?ref=v1.0.8"
  source = "../../modules/lb-listener-rules"

  default_listener_arns  = module.alb.listener_arns
  default_listener_ports = [local.alb_listener_port]

  default_forward_target_group_arns = [
    {
      arn = aws_lb_target_group.example_server.arn
    }
  ]

  forward_rules = {
    "hello" = {
      priority      = 120
      port          = var.server_port
      path_patterns = ["/*"]

      stickiness = {
        enabled  = true
        duration = 200
      }
    },
    "world" = {
      priority = 130
      port     = var.server_port

      path_patterns = ["/super_secure_path", "/another_path"]
      http_headers = [
        {
          http_header_name = "X-Forwarded-For"
          values           = ["127.0.0.1"]
        }
      ]
    }
  }

  redirect_rules = {
    "foo-to-bar" = {
      priority    = 100
      status_code = "HTTP_301"
      path        = "/foo"

      path_patterns = ["/bar/", "/bar"]
    }
  }

  fixed_response_rules = {
    "hello-json" = {
      priority = 110

      content_type = "application/json"
      message_body = "{\"hello\": \"grunt\"}"
      status_code  = 200

      query_strings = [
        {
          key   = "response-type"
          value = "json"
        }
      ]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LAUNCH SAMPLE EC2 INSTANCE
# Launch a sample EC2 Instance that will run a basic server that can be accessed via the ALB.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "example_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = module.instance_type.recommended_instance_type
  key_name                    = var.keypair_name
  vpc_security_group_ids      = [aws_security_group.example_server.id]
  subnet_id                   = tolist(data.aws_subnet_ids.default.ids)[0]
  associate_public_ip_address = true
  user_data                   = local.user_data

  tags = {
    Name = "${var.alb_name}-alb-example"
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

  # Inbound SSH from anywhere. This is just for testing. In prod, you should only allow SSH
  # access from trusted servers (e.g., from a bastion host).
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # To make testing easy, we allow inbound HTTP from anywhere, but in prod, you should lock
  # this down to just inbound HTTP from the load balancer.
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.alb_name}-alb-example"
  }
}

module "instance_type" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-utilities.git//modules/instance-type?ref=v0.2.1"

  # Run example_server using one of those two instance types. The tests run in a random region, sometimes the instance
  # type isn't available in one availability zone.
  instance_types = ["t2.micro", "t3.micro"]
}

# ---------------------------------------------------------------------------------------------------------------------
# REGISTER SAMPLE SERVER AS A BACKEND FOR ALB
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb_target_group" "example_server" {
  name     = "${var.alb_name}-alb-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_target_group_attachment" "example_server" {
  target_group_arn = aws_lb_target_group.example_server.id
  target_id        = aws_instance.example_server.id
  port             = var.server_port
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE USER DATA SCRIPT TO RUN WHEN EACH EC2 INSTANCE BOOTS
# This script runs a simple web server with /, /foo and /bar paths.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  user_data = templatefile(
    "${path.module}/user_data.sh",
    {
      server_port = var.server_port
    },
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# LOOKUP EXISTING RESOURCES TO USE
# - Default VPC
# - Latest Ubuntu AMI
# ---------------------------------------------------------------------------------------------------------------------

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
