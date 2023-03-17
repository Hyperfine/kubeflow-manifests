output "alb_name" {
  value = module.alb.alb_name
}

output "alb_arn" {
  value = module.alb.alb_arn
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_hosted_zone_id" {
  value = module.alb.alb_hosted_zone_id
}

output "alb_security_group_id" {
  value = module.alb.alb_security_group_id
}

output "listener_arns" {
  value = module.alb.listener_arns
}

# Outputs a map whose key is a port on which there exists an ALB HTTP Listener, and whose value is the ARN of that Listener.
output "http_listener_arns" {
  value = module.alb.http_listener_arns
}

# Outputs a map whose key is a port on which there exists an ALB HTTPS Listener that uses a non-ACM cert, and whose value is the ARN of that Listener.
output "https_listener_non_acm_cert_arns" {
  value = module.alb.https_listener_non_acm_cert_arns
}

# Outputs a map whose key is a port on which there exists an ALB HTTPS Listener that uses an ACM cert, and whose value is the ARN of that Listener.
output "https_listener_acm_cert_arns" {
  value = module.alb.https_listener_acm_cert_arns
}
