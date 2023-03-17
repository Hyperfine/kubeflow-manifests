terraform {
  required_version = ">= 0.12"
}

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
  environment_name = "example"
  is_internal_alb  = false

  http_listener_ports = []
  ssl_policy          = "ELBSecurityPolicy-TLS-1-1-2017-01"

  https_listener_ports_and_acm_ssl_certs = [
    {
      port            = 443
      tls_domain_name = module.cert.certificate_domain_name
    },
  ]
  https_listener_ports_and_acm_ssl_certs_num = 1

  vpc_id         = data.aws_vpc.default.id
  vpc_subnet_ids = data.aws_subnet_ids.default.ids
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN TLS CERT USING ACM
# ---------------------------------------------------------------------------------------------------------------------

module "cert" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-load-balancer.git//modules/acm-tls-certificate?ref=v1.0.8"
  source = "../../modules/acm-tls-certificate"

  domain_name       = var.domain_name
  hosted_zone_id    = var.hosted_zone_id
  run_destroy_check = var.run_destroy_check
}

# ---------------------------------------------------------------------------------------------------------------------
# POINT THE DOMAIN NAME AT THE LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route53_record" "alb" {
  name    = var.domain_name
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_hosted_zone_id
    evaluate_target_health = true
  }
}
