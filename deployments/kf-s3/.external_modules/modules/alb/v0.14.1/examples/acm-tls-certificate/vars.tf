# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "alb_name" {
  description = "The name of the ALB. Do not include the environment name since this module will automatically append it to the value of this variable."
  type        = string
}

variable "domain_name" {
  description = "The domain name to point at the ALB and for which a TLS cert should be requested (e.g., foo.com or *.foo.com)"
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

variable "run_destroy_check" {
  description = "If set to true, before allowing the ACM certificate to be destroy, check that it is no longer in use. This check is a workaround for using ACM certs with API Gateway where, without it, the destroy will fail. This check relies on the AWS CLI being installed. It uses a Bash script, so it will not work on Windows."
  type        = bool
  default     = false
}
