output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alarm_sns_topic_arn" {
  value = aws_sns_topic.cloudwatch_alarms.arn
}
