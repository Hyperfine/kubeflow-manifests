terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

data aws_route53_zone "kubeflow" {
  name = "${var.subdomain_name}.${var.domain_name}"
}

data aws_lb "main" {
  tags = {
    "ingress.k8s.aws/cluster": var.cluster_name
  }
}

resource "aws_route53_record" "main" {
  name    = "*.${data.aws_route53_zone.kubeflow.name}"
  type    = "CNAME"
  zone_id = data.aws_route53_zone.kubeflow.zone_id
  ttl = 5
  records = [data.aws_lb.main.dns_name]
}

resource "aws_route53_record" "default" {
  name    = "*.default.${data.aws_route53_zone.kubeflow.name}"
  type    = "CNAME"
  zone_id = data.aws_route53_zone.kubeflow.zone_id
  ttl = 5
  records = [data.aws_lb.main.dns_name]
}

resource "aws_route53_record" "a_record" {
  name    = data.aws_route53_zone.kubeflow.name
  type    = "A"
  zone_id = data.aws_route53_zone.kubeflow.zone_id

  alias {
    evaluate_target_health = false
    name                   = data.aws_lb.main.dns_name
    zone_id                = data.aws_lb.main.zone_id
  }
  allow_overwrite = true
}