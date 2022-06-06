data "aws_route53_zone" "top" {
    zone_id = var.top_zone_id
}

locals {
  domain_name = data.aws_route53_zone.top.name
  cognito_url = "auth.${var.subdomain_name}.${local.domain_name}"
}
