output "alb_name" {
  description = "The name of the ALB that has been deployed using this module."
  value       = aws_alb.alb.name
}

output "alb_arn" {
  description = "The AWS ARN of the ALB that has been deployed using this module."
  value       = aws_alb.alb.arn
}

output "alb_dns_name" {
  description = "The DNS name that can be used to reach the ALB that has been deployed using this module."
  value       = aws_alb.alb.dns_name
}

output "alb_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID that manages the DNS record for the ALB that has been deployed using this module."
  value       = aws_alb.alb.zone_id
}

output "alb_security_group_id" {
  description = "The AWS ID of the security group for the ALB that has been deployed using this module."
  value       = aws_security_group.alb.id
}

output "listener_arns" {
  description = "A map from port to the AWS ARNs of the listeners for the ALB that has been deployed using this module."
  value = merge(
    zipmap(
      var.http_listener_ports,
      slice(aws_alb_listener.http.*.arn, 0, length(var.http_listener_ports))
    ),
    zipmap(
      local.non_acm_https_listener_ports,
      slice(aws_alb_listener.https_non_acm_certs.*.arn, 0, length(local.non_acm_https_listener_ports))
    ),
    zipmap(
      local.acm_https_listener_ports,
      slice(aws_alb_listener.https_acm_certs.*.arn, 0, length(local.acm_https_listener_ports))
    ),
  )
}

output "http_listener_arns" {
  description = "A map from port to the AWS ARNs of the HTTP listener for the ALB that has been deployed using this module."
  value = zipmap(
    var.http_listener_ports,
    slice(aws_alb_listener.http.*.arn, 0, length(var.http_listener_ports))
  )
}

output "https_listener_non_acm_cert_arns" {
  description = "A map from port to the AWS ARNs of the HTTPS listener that uses non-ACM SSL certificates for the ALB that has been deployed using this module."
  value = zipmap(
    local.non_acm_https_listener_ports,
    slice(aws_alb_listener.https_non_acm_certs.*.arn, 0, length(local.non_acm_https_listener_ports))
  )
}

output "https_listener_acm_cert_arns" {
  description = "A map from port to the AWS ARNs of the HTTPS listener that uses ACM SSL certificates for the ALB that has been deployed using this module."
  value = zipmap(
    local.acm_https_listener_ports,
    slice(aws_alb_listener.https_acm_certs.*.arn, 0, length(local.acm_https_listener_ports))
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# INTERMEDIATE COMPUTATIONS
# The following locals are intermediate computations to make the output computations easier to manage
# ---------------------------------------------------------------------------------------------------------------------

locals {
  non_acm_https_listener_ports = [for listener_port_and_ssl_cert in var.https_listener_ports_and_ssl_certs : listener_port_and_ssl_cert["port"]]
  acm_https_listener_ports     = [for listener_port_and_acm_cert in var.https_listener_ports_and_acm_ssl_certs : listener_port_and_acm_cert["port"]]
}
