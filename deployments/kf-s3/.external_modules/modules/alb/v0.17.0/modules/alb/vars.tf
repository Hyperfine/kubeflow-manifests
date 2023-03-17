# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_account_id" {
  description = "The AWS Account ID in which the ALB and its S3 Bucket will be created."
  type        = string
}

variable "aws_region" {
  description = "The AWS region in which the ALB and its corresponding S3 Bucket used for logging will be created."
  type        = string
}

variable "alb_name" {
  description = "The name of the ALB. Do not include the environment name since this module will automatically append it to the value of this variable."
  type        = string
}

variable "is_internal_alb" {
  description = "If the ALB should only accept traffic from within the VPC, set this to true. If it should accept traffic from the public Internet, set it to false."
  type        = bool
}

variable "additional_security_group_ids" {
  description = "Add additional security groups to the ALB"
  type        = list(string)
  default     = []
}

variable "ssl_policy" {
  description = "The AWS predefined TLS/SSL policy for the ALB. A List of policies can be found here: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies. AWS recommends ELBSecurityPolicy-2016-08 policy for general use but this policy includes TLSv1.0 which is rapidly being phased out. ELBSecurityPolicy-TLS-1-1-2017-01 is the next policy up that doesn't include TLSv1.0."
  type        = string
}

# Info about the VPC in which this Cluster resides
variable "vpc_id" {
  description = "The VPC ID in which this ALB will be placed."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "A list of the subnets into which the ALB will place its underlying nodes. Include one subnet per Availabability Zone. If the ALB is public-facing, these should be public subnets. Otherwise, they should be private subnets."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "http_listener_ports" {
  description = "A list of ports for which an HTTP Listener should be created on the ALB. Tip: When you define Listener Rules for these Listeners, be sure that, for each Listener, at least one Listener Rule uses the '*' path to ensure that every possible request path for that Listener is handled by a Listener Rule. Otherwise some requests won't route to any Target Group."
  type        = list(string)
  default     = []
}

variable "https_listener_ports_and_ssl_certs" {
  description = "A list of the ports for which an HTTPS Listener should be created on the ALB. Each item in the list should be a map with the keys 'port', the port number to listen on, and 'tls_arn', the Amazon Resource Name (ARN) of the SSL/TLS certificate to associate with the Listener to be created. If your certificate is issued by the Amazon Certificate Manager (ACM), specify var.https_listener_ports_and_acm_ssl_certs instead. Tip: When you define Listener Rules for these Listeners, be sure that, for each Listener, at least one Listener Rule  uses the '*' path to ensure that every possible request path for that Listener is handled by a Listener Rule. Otherwise some requests won't route to any Target Group."
  type = list(object({
    port    = number
    tls_arn = string
  }))
  default = []

  # Example:
  # default = [
  #   {
  #     port = 443
  #     tls_arn = "arn:aws:iam::123456789012:server-certificate/ProdServerCert"
  #   }
  # ]
}

variable "https_listener_ports_and_ssl_certs_num" {
  description = "The number of elements in var.https_listener_ports_and_ssl_certs. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.https_listener_ports_and_ssl_certs, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "https_listener_ports_and_acm_ssl_certs" {
  description = "A list of the ports for which an HTTPS Listener should be created on the ALB. Each item in the list should be a map with the keys 'port', the port number to listen on, and 'tls_domain_name', the domain name of an SSL/TLS certificate issued by the Amazon Certificate Manager (ACM) to associate with the Listener to be created. If your certificate isn't issued by ACM, specify var.https_listener_ports_and_ssl_certs instead. Tip: When you define Listener Rules for these Listeners, be sure that, for each Listener, at least one Listener Rule  uses the '*' path to ensure that every possible request path for that Listener is handled by a Listener Rule. Otherwise some requests won't route to any Target Group."
  type = list(object({
    port            = number
    tls_domain_name = string
  }))
  default = []

  # Example:
  # default = [
  #   {
  #     port = 443
  #     tls_domain_name = "foo.your-company.com"
  #   }
  # ]
}

variable "https_listener_ports_and_acm_ssl_certs_num" {
  description = "The number of elements in var.https_listener_ports_and_acm_ssl_certs. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.https_listener_ports_and_acm_ssl_certs, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "allow_all_outbound" {
  description = "Set to true to enable all outbound traffic on this ALB. If set to false, the ALB will allow no outbound traffic by default. This will make the ALB unusuable, so some other code must then update the ALB Security Group to enable outbound access!"
  type        = bool
  default     = true
}

variable "enable_alb_access_logs" {
  description = "Set to true to enable the ALB to log all requests. Ideally, this variable wouldn't be necessary, but because Terraform can't interpolate dynamic variables in counts, we must explicitly include this. Enter true or false."
  type        = bool
  default     = false
}

variable "alb_access_logs_s3_bucket_name" {
  description = "The S3 Bucket name where ALB logs should be stored. If left empty, no ALB logs will be captured. Tip: It's easiest to create the S3 Bucket using the Gruntwork Module https://github.com/gruntwork-io/module-aws-monitoring/tree/master/modules/logs/load-balancer-access-logs."
  type        = string
  default     = null
}

variable "allow_inbound_from_cidr_blocks" {
  description = "The CIDR-formatted IP Address ranges from which this ALB will allow incoming requests. If var.is_internal_alb is false, use the default value. If var.is_internal_alb is true, consider setting this to the VPC's CIDR Block, or something even more restrictive."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_inbound_from_security_group_ids" {
  description = "The IDs of security groups from which this ALB will allow incoming requests. . If you update this variable, make sure to update var.allow_inbound_from_security_group_ids_num too!"
  type        = list(string)
  default     = []
}

variable "allow_inbound_from_security_group_ids_num" {
  description = "The number of elements in var.allow_inbound_from_security_group_ids. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_security_group_ids, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "idle_timeout" {
  description = "The time in seconds that the client TCP connection to the ALB is allowed to be idle before the ALB closes the TCP connection.  "
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the ALB will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer."
  type        = bool
  default     = false
}

variable "custom_tags" {
  description = "A map of custom tags to apply to the ALB and its Security Group. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "default_action_content_type" {
  description = "If a request to the load balancer does not match any of your listener rules, the default action will return a fixed response with this content type."
  type        = string
  default     = "text/plain"
}

variable "default_action_body" {
  description = "If a request to the load balancer does not match any of your listener rules, the default action will return a fixed response with this body."
  type        = string
  default     = null
}

variable "default_action_status_code" {
  description = "If a request to the load balancer does not match any of your listener rules, the default action will return a fixed response with this status code."
  type        = number
  default     = 404
}
