output "topic_name" {
  value = join("", aws_sns_topic.topic.*.name)
}

output "topic_display_name" {
  value = var.create_resources ? format("%.10s", var.display_name) : null
}

output "topic_arn" {
  value = join("", aws_sns_topic.topic.*.arn)
}

output "topic_policy" {
  value = join("", aws_sns_topic.topic.*.policy)
}
