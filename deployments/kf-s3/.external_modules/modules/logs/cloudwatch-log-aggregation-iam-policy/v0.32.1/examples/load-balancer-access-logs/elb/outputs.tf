output "elb_dns_name" {
  value = aws_elb.example.dns_name
}

output "access_logs_s3_bucket_name" {
  value = module.elb_access_logs_bucket.s3_bucket_name
}
