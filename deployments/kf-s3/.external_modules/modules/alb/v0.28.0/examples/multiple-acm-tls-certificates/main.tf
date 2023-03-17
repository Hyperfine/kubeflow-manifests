terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AND VALIDATE MULTIPLE TLS CERT(S) USING ACM
# ---------------------------------------------------------------------------------------------------------------------

module "cert" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-load-balancer.git//modules/acm-tls-certificate?ref=v1.0.8"
  source = "../../modules/acm-tls-certificate"

  acm_tls_certificates = var.acm_tls_certificates

  # Default certificate verification variables
  default_create_verification_record = var.default_create_verification_record
  default_verify_certificate         = var.default_verify_certificate
}
