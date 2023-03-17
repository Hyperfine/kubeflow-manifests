# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "domain_name" {
  description = "The domain name for which to issue a TLS certificate (e.g., foo.com or *.foo.com)."
  type        = string
}

variable "hosted_zone_id" {
  description = "The ID of the Route 53 Hosted Zone in which to create a DNS record to use for DNS validation of the TLS certificate. Should be the hosted zone that is the parent of var.domain_name."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "subject_alternative_names" {
  description = "A list of additional domains that should be SANs in the issued certificate."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the ACM certificate."
  type        = map(string)
  default     = {}
}

variable "run_destroy_check" {
  description = "If set to true, before allowing the ACM certificate to be destroy, check that it is no longer in use. This check is a workaround for using ACM certs with API Gateway where, without it, the destroy will fail. This check relies on the AWS CLI being installed. It uses a Bash script, so it will not work on Windows."
  type        = bool
  default     = false
}

variable "create_resources" {
  description = "If you set this variable to false, this module will not create any resources. This is used as a workaround because Terraform does not allow you to use the 'count' parameter on modules. By using this parameter, you can optionally create or not create the resources within this module."
  type        = bool
  default     = true
}
