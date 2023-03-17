output "certificate_arns" {
  value = values(local.requested_certificates).*.arn

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}

output "certificate_ids" {
  value = values(local.requested_certificates).*.id

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}

output "certificate_domain_names" {
  value = values(local.requested_certificates).*.domain_name

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
}

output "certificate_domain_validation_options" {
  value = values(local.requested_certificates).*.domain_validation_options

  # All the outputs wait on the certificate validation to complete so users of this module don't accidentally try to
  # make use of a cert that has not yet been validated.
  depends_on = [aws_acm_certificate_validation.cert]
} 
