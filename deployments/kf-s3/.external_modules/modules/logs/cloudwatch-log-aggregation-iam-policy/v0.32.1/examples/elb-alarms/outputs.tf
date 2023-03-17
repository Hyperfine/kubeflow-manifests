output "elb_dns_name" {
  value = aws_elb.example.dns_name
}

output "alarm_sns_topic_arn" {
  value = aws_sns_topic.cloudwatch_alarms.arn
}
