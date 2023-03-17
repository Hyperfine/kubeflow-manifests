# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE TLS CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

resource "aws_acm_certificate" "cert" {
  count = var.create_resources ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  tags                      = var.tags

  # This is to work around a bug that happens on 'terraform destroy'. If you attach this TLS certificate to aresources
  # (e.g., ALB, API Gateway), you can't destroy this certificate until you destroy that other resource. Some of those
  # resources—namely, API Gateway—can take a VERY long time to destroy (10 - 30 minutes). Unfortunately, Terraform
  # waits a maximum of 10 minutes to destroy an ACM certificate and then times out with an error, so with those slow
  # resources, destroy does not complete successfully. To work around it, we use the AWS CLI below to explicitly check
  # if this certificate is still in use and don't allow the delete to happen until it's no longer in use.
  # This is to work around a bug that happens on 'terraform destroy'. If you attach this TLS certificate to aresources
  # (e.g., ALB, API Gateway), you can't destroy this certificate until you destroy that other resource. Some of those
  # resources—namely, API Gateway—can take a VERY long time to destroy (10 - 30 minutes). Unfortunately, Terraform
  # waits a maximum of 10 minutes to destroy an ACM certificate and then times out with an error, so with those slow
  # resources, destroy does not complete successfully. To work around it, we use the AWS CLI below to explicitly check
  # if this certificate is still in use and don't allow the delete to happen until it's no longer in use.
  provisioner "local-exec" {
    when    = destroy
    command = var.run_destroy_check ? "${path.module}/wait-until-tls-cert-not-in-use.sh ${data.aws_region.current.name} ${self.arn}" : "true"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A ROUTE 53 RECORD TO VALIDATE THE CERT
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route53_record" "cert_validation" {
  count   = var.create_resources ? 1 : 0
  name    = local.flattened_domains[0]["resource_record_name"]
  type    = local.flattened_domains[0]["resource_record_type"]
  zone_id = var.hosted_zone_id
  records = [local.flattened_domains[0]["resource_record_value"]]
  ttl     = 60
}

# ---------------------------------------------------------------------------------------------------------------------
# VALIDATE THE TLS CERT USING DNS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_acm_certificate_validation" "cert" {
  count                   = var.create_resources ? 1 : 0
  certificate_arn         = local.certificate_arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]
}

# ---------------------------------------------------------------------------------------------------------------------
# SOME LOCAL VARS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  certificate_arn         = element(concat(aws_acm_certificate.cert.*.arn, [""]), 0)
  certificate_id          = element(concat(aws_acm_certificate.cert.*.id, [""]), 0)
  certificate_domain_name = element(concat(aws_acm_certificate.cert.*.domain_name, [""]), 0)

  # Workaround for https://github.com/hashicorp/terraform/issues/18359
  flattened_domains = flatten(concat(aws_acm_certificate.cert.*.domain_validation_options))
}
