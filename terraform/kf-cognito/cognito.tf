resource "aws_route53_zone" "kubeflow_zone" {
  name = "${var.subdomain_name}.${local.domain_name}"
  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "kubeflow_ns" {
  name = aws_route53_zone.kubeflow_zone.name
  type = "NS"
  ttl = "30"
  zone_id = data.aws_route53_zone.top.zone_id
  records = aws_route53_zone.kubeflow_zone.name_servers
}


module "acm_cognito" {
  count = var.public_acm ? 1 : 0

  depends_on = [aws_route53_record.kubeflow_ns]
  source = "terraform-aws-modules/acm/aws"
  version = "3.4.1"
  providers = {
    aws = aws.us_east_1 # cognito needs us-east-1
  }

  domain_name               = local.cognito_url
  zone_id                   = aws_route53_zone.kubeflow_zone.zone_id
  subject_alternative_names = ["*.${local.cognito_url}"]
  wait_for_validation       = true
}

module "acm_kubeflow" {
  count = var.public_acm ? 1 : 0

  depends_on = [aws_route53_record.kubeflow_ns]
  source = "terraform-aws-modules/acm/aws"
  version = "3.4.1"
  domain_name               = aws_route53_zone.kubeflow_zone.name
  zone_id                   = aws_route53_zone.kubeflow_zone.zone_id
  subject_alternative_names = ["*.${aws_route53_zone.kubeflow_zone.name}"]
  wait_for_validation       = true
}

resource "aws_cognito_user_pool" "pool" {
  name = "${aws_route53_zone.kubeflow_zone.name}-user-pool"
}


# message: Custom domain is not a valid subdomain: Was not able to resolve the root domain, please ensure an A record exists for the root domain.
resource "aws_route53_record" "dummy" {
  count = var.first_run ? 1 : 0
  name    = aws_route53_zone.kubeflow_zone.name
  type    = "A"
  zone_id = aws_route53_zone.kubeflow_zone.zone_id
  ttl = 300
  records = ["127.0.0.1"]
  allow_overwrite = true
}


resource "time_sleep" "wait_30_seconds" {
  depends_on = [aws_route53_record.dummy]

  create_duration = "30s"
}

resource "aws_cognito_user_pool_domain" "main" {
  depends_on = [time_sleep.wait_30_seconds]
  domain          = "auth.platform.hyperfine.aws"
  certificate_arn = local.cert_arn
  user_pool_id    = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_client" "client" {
  name = "${aws_route53_zone.kubeflow_zone.name}-cognito-client"

  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret = true
  callback_urls = [
      "https://kubeflow.${aws_route53_zone.kubeflow_zone.name}/oauth2/idpresponse",
      "https://kubeflow.${local.cognito_url}/oauth2/idpresponse"
  ]
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers = ["COGNITO"]
  allowed_oauth_flows = [
    "code",
    "implicit"
  ]

  allowed_oauth_scopes = [
    "email",
    "openid",
    "aws.cognito.signin.user.admin",
    "profile"
  ]
}

locals {
  cert_arn = var.public_acm ? module.acm_kubeflow.acm_certificate_arn : null
}
