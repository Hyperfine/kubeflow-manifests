output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "target_group_name" {
  value = aws_alb_target_group.test.name
}

output "alarm_sns_topic_arn" {
  value = aws_sns_topic.cloudwatch_alarms.arn
}
