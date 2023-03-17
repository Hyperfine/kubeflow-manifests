output "queue_name" {
  value = join("", aws_sqs_queue.queue[*].name)
}

output "queue_url" {
  value = join("", aws_sqs_queue.queue[*].id)
}

output "queue_arn" {
  value = join("", aws_sqs_queue.queue[*].arn)
}

# Only shows up if var.dead_letter_queue is true
output "dead_letter_queue_name" {
  value = join("", aws_sqs_queue.dead_letter_queue[*].name)
}

# Only shows up if var.dead_letter_queue is true
output "dead_letter_queue_url" {
  value = join("", aws_sqs_queue.dead_letter_queue[*].id)
}

# Only shows up if var.dead_letter_queue is true
output "dead_letter_queue_arn" {
  value = join("", aws_sqs_queue.dead_letter_queue[*].arn)
}
