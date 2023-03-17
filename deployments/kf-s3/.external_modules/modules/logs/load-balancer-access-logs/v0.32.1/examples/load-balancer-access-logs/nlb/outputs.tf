output "nlb_dns_name" {
  value = aws_lb.example.dns_name
}

output "access_logs_s3_bucket_name" {
  value = module.nlb_access_logs_bucket.s3_bucket_name
}
