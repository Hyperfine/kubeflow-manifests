output "nlb_name" {
  value = element(
    concat(
      aws_lb.nlb.*.name,
      aws_lb.nlb_1_az.*.name,
      aws_lb.nlb_2_az.*.name,
      aws_lb.nlb_3_az.*.name,
      aws_lb.nlb_4_az.*.name,
      aws_lb.nlb_5_az.*.name,
      aws_lb.nlb_6_az.*.name,
    ),
    0,
  )
}

output "nlb_arn" {
  value = element(
    concat(
      aws_lb.nlb.*.arn,
      aws_lb.nlb_1_az.*.arn,
      aws_lb.nlb_2_az.*.arn,
      aws_lb.nlb_3_az.*.arn,
      aws_lb.nlb_4_az.*.arn,
      aws_lb.nlb_5_az.*.arn,
      aws_lb.nlb_6_az.*.arn,
    ),
    0,
  )
}

output "nlb_dns_name" {
  value = element(
    concat(
      aws_lb.nlb.*.dns_name,
      aws_lb.nlb_1_az.*.dns_name,
      aws_lb.nlb_2_az.*.dns_name,
      aws_lb.nlb_3_az.*.dns_name,
      aws_lb.nlb_4_az.*.dns_name,
      aws_lb.nlb_5_az.*.dns_name,
      aws_lb.nlb_6_az.*.dns_name,
    ),
    0,
  )
}

output "nlb_hosted_zone_id" {
  value = element(
    concat(
      aws_lb.nlb.*.zone_id,
      aws_lb.nlb_1_az.*.zone_id,
      aws_lb.nlb_2_az.*.zone_id,
      aws_lb.nlb_3_az.*.zone_id,
      aws_lb.nlb_4_az.*.zone_id,
      aws_lb.nlb_5_az.*.zone_id,
      aws_lb.nlb_6_az.*.zone_id,
    ),
    0,
  )
}

# Outputs a map whose key is a port on which there exists an NLB TCP Listener, and whose value is the ARN of that Listener.
output "tcp_listener_arns" {
  value = zipmap(var.tcp_listener_ports, aws_lb_listener.tcp.*.arn)
}
