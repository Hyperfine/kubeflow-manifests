variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "eu-west-1"
}

variable "alb_name" {
  description = "The name of the ALB. Do not include the environment name since the ALB module will automatically append it to the value of this variable."
  type        = string
  default     = "lb-listener-rule-example"
}

variable "keypair_name" {
  description = "The SSH keypair to use for the example server."
  type        = string
  default     = null
}

variable "server_port" {
  description = "The port that the example server should listen on."
  default     = 8080
  type        = number
}