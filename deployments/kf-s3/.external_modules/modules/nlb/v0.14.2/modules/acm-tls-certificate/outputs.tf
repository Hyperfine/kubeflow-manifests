output "certificate_arn" {
  value = local.certificate_arn

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}

output "certificate_id" {
  value = local.certificate_id

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}

output "certificate_domain_name" {
  value = local.certificate_domain_name

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}

output "certificate_domain_validation_options" {
  value = local.flattened_domains

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}
