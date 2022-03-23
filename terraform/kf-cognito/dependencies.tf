data "aws_route53_zone" "top" {
    name = var.domain_name
}

locals {
  cognito_url = "auth.platform.${var.domain_name}"
}