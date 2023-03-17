output "certificate_arns" {
  value = [for cert in local.requested_certificates : cert.arn]

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}

output "certificate_ids" {
  value = [for cert in local.requested_certificates : cert.id]

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}

output "certificate_domain_names" {
  value = [for cert in local.requested_certificates : cert.domain_name]

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}

output "certificate_domain_validation_options" {
  value = [for cert in local.requested_certificates : cert.domain_validation_options]

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}
