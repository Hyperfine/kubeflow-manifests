output "nlb_name" {
  value = var.nlb_name

  depends_on = [aws_lb.nlb]
}

output "nlb_arn" {
  value = aws_lb.nlb.arn
}

output "nlb_dns_name" {
  value = aws_lb.nlb.dns_name
}

output "nlb_hosted_zone_id" {
  value = aws_lb.nlb.zone_id
}

output "public_ips" {
  value = [aws_eip.example1.public_ip, aws_eip.example2.public_ip]
}
