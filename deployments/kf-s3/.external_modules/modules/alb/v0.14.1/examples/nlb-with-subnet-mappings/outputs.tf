output "nlb_name" {
  value = module.nlb.nlb_name
}

output "nlb_arn" {
  value = module.nlb.nlb_arn
}

output "nlb_dns_name" {
  value = module.nlb.nlb_dns_name
}

output "nlb_hosted_zone_id" {
  value = module.nlb.nlb_hosted_zone_id
}

# Outputs a map whose key is a port on which there exists an NLB TCP Listener, and whose value is the ARN of that Listener.
output "tcp_listener_arns" {
  value = module.nlb.tcp_listener_arns
}

output "public_ips" {
  value = [aws_eip.example1.public_ip, aws_eip.example2.public_ip]
}
