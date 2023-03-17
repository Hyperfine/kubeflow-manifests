
terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# SET MODULE DEPENDENCY RESOURCE
# This works around a terraform limitation where we can not specify module dependencies natively.
# See https://github.com/hashicorp/terraform/issues/1178 for more discussion.
# By resolving and computing the dependencies list, we are able to make all the resources in this module depend on the
# resources backing the values in the dependencies list.
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "dependency_getter" {
  triggers = {
    instance = join(",", var.dependencies)
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE TLS CERTIFICATE(S)
# ---------------------------------------------------------------------------------------------------------------------

# Create a certificate for each of the defined certificate inputs 
# defined in the nested map local.acm_tls_certificates
resource "aws_acm_certificate" "cert" {
  for_each = local.acm_tls_certificates

  # Normalize domain name - whether the user added a trailing dot or not, ensure the trailing dot is present
  # This helps prevent some state change errors where the AWS provider may return a domain name with a trailing dot, 
  # which causes Terraform to see the input map that is provided to for_each loops has been changed at runtime,
  # leading to very obscure errors
  domain_name               = trimsuffix(each.key, ".")
  subject_alternative_names = each.value.subject_alternative_names
  validation_method         = "DNS"

  tags = each.value.tags

  lifecycle {
    # Official Terraform provider docs for aws_acm_certificate recommend 
    # setting create_before_destroy to true, especially for a certificate
    # that may be in use by a critical resource such as an aws_lb_listener
    # as this could help prevent downtime due to a missing certificate 
    create_before_destroy = true
    # Subject alternative names are returned by an asynchronous API 
    # that makes no guarantees about their order. 
    #
    # Passing the subject_alternative_names field into ignore_changes
    # prevents Terraform from seeing changes in the order of returned SANs 
    # as representing resource changes
    #
    # See: https://github.com/terraform-providers/terraform-provider-aws/issues/8531
    ignore_changes = [subject_alternative_names]
  }

  # This is to work around a bug that happens on 'terraform destroy'. If you attach this TLS certificate to a resource
  # (e.g., ALB, API Gateway), you can't destroy this certificate until you destroy that other resource. Some of those
  # resources—namely, API Gateway—can take a VERY long time to destroy (10 - 30 minutes). Unfortunately, Terraform
  # waits a maximum of 10 minutes to destroy an ACM certificate and then times out with an error, so with those slow
  # resources, destroy does not complete successfully. To work around it, we use the AWS CLI below to explicitly check
  # if this certificate is still in use and don't allow the delete to happen until it's no longer in use.

  # Tags are specifically used because provisioners no longer support referencing vars or attributes
  # from other resources 

  # If you want this destroy-time provisioner to run, add the tag "run_destroy_check" in your input variable
  # certificate object's tags map and set its value to true
  provisioner "local-exec" {
    when    = destroy
    command = tobool(lookup(self.tags, "run_destroy_check", false)) ? "${path.module}/wait-until-tls-cert-not-in-use.sh ${self.arn}" : "true"
  }

  depends_on = [null_resource.dependency_getter]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ROUTE 53 RECORD(S) TO VALIDATE THE CERT(S)
# ---------------------------------------------------------------------------------------------------------------------

# Create a DNS validation record for every certificate input that has 
# create_verification_record set to true 

# AWS ACM will use these DNS records to validate certificates it issues 
resource "aws_route53_record" "cert_validation" {
  for_each = local.dns_verification_records_to_create

  allow_overwrite = true

  name    = each.value.validation_options.0.resource_record_name
  type    = each.value.validation_options.0.resource_record_type
  zone_id = each.value.zone_id
  records = [each.value.validation_options.0.resource_record_value]
  ttl     = 60

  depends_on = [null_resource.dependency_getter]
}

# ---------------------------------------------------------------------------------------------------------------------
# VALIDATE THE TLS CERT(S) USING DNS
# ---------------------------------------------------------------------------------------------------------------------

# A certificate_validation is not truly a resource, but is an action within the 
# AWS certificate issuance and validation process
#
# See: https://www.terraform.io/docs/providers/aws/r/acm_certificate_validation.html
resource "aws_acm_certificate_validation" "cert" {
  # Certificate validation actions are only initiated against 
  # 1. records that were created via create_verification_record == true 
  # 2. records for which verification was requested via verify_certificate == true 
  # Note that the default values: var.default_verify_certificate and var.default_create_verification_record
  # are also considered when building the local.acm_tls_certificates map
  for_each = {
    for key, c in aws_acm_certificate.cert :
    key => c if local.acm_tls_certificates[key].verify_certificate &&
    local.acm_tls_certificates[key].create_verification_record
  }

  certificate_arn         = each.value.arn
  validation_record_fqdns = each.value.domain_validation_options.*.resource_record_name
  depends_on              = [aws_route53_record.cert_validation, null_resource.dependency_getter]
}


# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VARS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Loop through var.acm_tls_certificates, merging default variables 
  acm_tls_certificates = { for domain, cert in var.acm_tls_certificates :
    domain => {
      verify_certificate         = tobool(lookup(cert, "verify_certificate", var.default_verify_certificate))
      create_verification_record = tobool(lookup(cert, "create_verification_record", var.default_create_verification_record))
      subject_alternative_names  = lookup(cert, "subject_alternative_names", [])
      tags                       = merge(var.global_tags, lookup(cert, "tags", {}))
      hosted_zone_id             = lookup(cert, "hosted_zone_id", "") != "" ? cert.hosted_zone_id : data.aws_route53_zone.current[domain].zone_id
    }
  }

  # A flattened list of all domains, including both top-level keys and subject alternative names 
  # for which the certificate input's attribute create_verification_record is set to true
  list_of_all_domains_to_create_dns_records_for = flatten([
    for key, d in local.acm_tls_certificates : concat([key], d.subject_alternative_names) if d.create_verification_record
  ])

  # Example output: 
  # 
  # [
  #  "mail.example.com",
  #  "mailme.example.com",
  #  "smtp.example.com",
  #  "spare.example.com",
  #  "extra.example.com",
  # ]

  # A flattened list of the source domains - for which certificates themselves are being requested. 
  # For example, a certificate requested for example.com might have subject alternative names (SANs) such as: 
  # mail.example.com and smtp.example.com
  list_of_all_source_domains_to_create_dns_records_for = flatten([
    for key, d in local.acm_tls_certificates : concat([key], [for san in d.subject_alternative_names : key]) if d.create_verification_record
  ])

  # Example output: 
  #
  # [
  #  "mail.example.com",
  #  "mail.example.com",
  #  "smtp.example.com",
  #  "spare.example.com",
  #  "spare.example.com",
  # ]

  # Build a map of the domains (which include SANs) to their source domains 
  # so that it's possible to look up a SAN's original source domain
  lookup_from_domain_to_source_for_dns_record_creation = zipmap(
    local.list_of_all_domains_to_create_dns_records_for,
    local.list_of_all_source_domains_to_create_dns_records_for
  )

  # Example output: 
  # {
  #  "mail.example.com" = "mail.example.com"
  #  "mailme.example.com" = "mail.example.com"
  #  "smtp.example.com" = "smtp.example.com"
  #  "spare.example.com" = "spare.example.com"
  #  "extra.example.com" = "spare.example.com"
  # }

  # A map of AWS ACM certificates that were issued 
  requested_certificates = aws_acm_certificate.cert

  # The map of domain names to their domain validation options 
  # for use in looping through during route53 record creation 

  # We create a record for every certificate input that has create_verification_record set to true 
  dns_verification_records_to_create = { for domain, source_domain in local.lookup_from_domain_to_source_for_dns_record_creation :
    domain => {
      validation_options = [
        for domain_validation_options in local.requested_certificates[source_domain].domain_validation_options :
        domain_validation_options if domain_validation_options.domain_name == trimsuffix(domain, ".")
      ]
      zone_id = local.acm_tls_certificates[source_domain].hosted_zone_id
    }
  }

  # Example output: 
  # {
  #  "mail.example.com" = [
  #   {
  #    "domain_name" = "mail.example.com"
  #    "resource_record_name" = "_623bc70f36798f08410934f5d0f44dec.mail.example.com."
  #    "resource_record_type" = "CNAME"
  #    "resource_record_value" = "_72f41e18680b86ea705cace44f2d8902.nhqijqilxf.acm-validations.aws."
  #   },
  #  ]
  #   "mailme.example.com" = [
  #    {
  #     "domain_name" = "mailme.example.com"
  #     "resource_record_name" = "_3e47ed506c9dd46c144dd7544962d3e3.mailme.example.com."
  #     "resource_record_type" = "CNAME"
  #     "resource_record_value" = "_60cff39d6219c849a8af50b03fdaccf5.nhqijqilxf.acm-validations.aws."
  #    },
  #]
  # ...

  data_zone_lookups_to_perform = {
    # This look up requires iterating through var.acm_tls_certificates to avoid a cycle error
    for domain, cert in var.acm_tls_certificates :
    domain => cert if lookup(cert, "hosted_zone_id", "") == ""
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# --------------------------------------------------------------------------------------------------------------------- 

data "aws_route53_zone" "current" {
  for_each = local.data_zone_lookups_to_perform
  # This module can be used to order wildcard cerificates, which are prefixed with "*.". In order to normalize 
  # zone lookups when we're not handling wildcard certificates, trim the "*." from the beginning of the 
  # zone name before performing the look up
  name         = trimprefix(each.key, "*.")
  private_zone = false

  # Adding depends_on to a data source prevents that data source from being read during the 'refresh' phase,
  # prior to plan. When this data source is read during refresh, for a zone that does not exist yet, it 
  # results in an error  
  # See: https://github.com/hashicorp/terraform/issues/17034 for additional info
  depends_on = [null_resource.dependency_getter]
}
