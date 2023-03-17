output "alb_dns_name" {
  value = aws_alb.example.dns_name
}

output "access_logs_s3_bucket_name" {
  value = module.alb_access_logs_bucket.s3_bucket_name
}
