output "topic_name" {
  value = aws_sns_topic.topic.name
}

output "topic_display_name" {
  value = format("%.10s", var.display_name)
}

output "topic_arn" {
  value = aws_sns_topic.topic.arn
}

output "topic_policy" {
  value = aws_sns_topic.topic.policy
}
