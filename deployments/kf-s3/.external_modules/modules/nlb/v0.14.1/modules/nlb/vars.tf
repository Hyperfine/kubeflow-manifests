# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which the NLB and its corresponding S3 Bucket used for logging will be created."
  type        = string
}

variable "nlb_name" {
  description = "The name of the NLB. Do not include the environment name since this module will automatically append it to the value of this variable."
  type        = string
}

variable "environment_name" {
  description = "The environment name in which the NLB is located. (e.g. stage, prod)"
  type        = string
}

variable "is_internal_nlb" {
  description = "If the NLB should only accept traffic from within the VPC, set this to true. If it should accept traffic from the public Internet, set it to false."
  type        = bool
}

variable "tcp_listener_ports" {
  description = "A list of ports for which a TCP Listener should be created on the NLB. Tip: When you define Listener Rules for these Listeners, be sure that, for each Listener, at least one Listener Rule  uses the '*' path to ensure that every possible request path for that Listener is handled by a Listener Rule. Otherwise some requests won't route to any Target Group."
  type        = list(string)
  default     = []
}

# Info about the VPC in which this Cluster resides
variable "vpc_id" {
  description = "The VPC ID in which this NLB will be placed."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "A list of the subnets into which the NLB will place its underlying nodes. Include one subnet per Availabability Zone. If the NLB is public-facing, these should be public subnets. Otherwise, they should be private subnets."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "enable_nlb_access_logs" {
  description = "Set to true to enable the NLB to log all requests. Ideally, this variable wouldn't be necessary, but because Terraform can't interpolate dynamic variables in counts, we must explicitly include this. Enter true or false."
  type        = bool
  default     = false
}

variable "nlb_access_logs_s3_bucket_name" {
  description = "The S3 Bucket name where NLB logs should be stored. If left empty, no NLB logs will be captured. Tip: It's easiest to create the S3 Bucket using the Gruntwork Module https://github.com/gruntwork-io/module-aws-monitoring/tree/master/modules/logs/load-balancer-access-logs."
  type        = string
  default     = null
}

variable "idle_timeout" {
  description = "The time in seconds that the client TCP connection to the NLB is allowed to be idle before the NLB closes the TCP connection."
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the NLB will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer."
  type        = bool
  default     = false
}

variable "custom_tags" {
  description = "A map of custom tags to apply to the NLB and its Security Group. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "subnet_mapping" {
  description = "A list of mapping of subnet IDs to IP Address allocations. Each item in the list should must have 'subnet_id' set and optionally 'allocation_id'"
  type        = list(map(string))
  default     = []

  # Example:
  #   [{
  #     subnet_id = "subnet-123234",
  #     allocation_id = "al23423"
  #   }]
  #
}

variable "subnet_mapping_size" {
  description = "The number of maps in the subnet_mapping list variable. Used to determine what nlb terraform resource to deploy and has to be specified due to Terraform limitations"
  type        = number
  default     = 0
}

variable "enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing of the load balancer will be enabled."
  type        = bool
  default     = false
}

variable "ip_address_type" {
  description = "The type of IP addresses used by the subnets for your load balancer. The possible values are ipv4 and dualstack"
  type        = string
  default     = "ipv4"
}
