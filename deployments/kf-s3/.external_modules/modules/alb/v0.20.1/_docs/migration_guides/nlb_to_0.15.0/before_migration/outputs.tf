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

output "public_ips" {
  value = [aws_eip.example1.public_ip, aws_eip.example2.public_ip]
}
