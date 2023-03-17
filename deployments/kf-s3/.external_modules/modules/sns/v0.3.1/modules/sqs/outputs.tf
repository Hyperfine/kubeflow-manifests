output "queue_name" {
  value = aws_sqs_queue.queue.name
}

output "queue_url" {
  value = aws_sqs_queue.queue.id
}

output "queue_arn" {
  value = aws_sqs_queue.queue.arn
}

# Only shows up if var.dead_letter_queue is true
output "dead_letter_queue_name" {
  value = element(concat(aws_sqs_queue.dead_letter_queue.*.name, [""]), 0)
}

# Only shows up if var.dead_letter_queue is true
output "dead_letter_queue_url" {
  value = element(concat(aws_sqs_queue.dead_letter_queue.*.id, [""]), 0)
}

# Only shows up if var.dead_letter_queue is true
output "dead_letter_queue_arn" {
  value = element(concat(aws_sqs_queue.dead_letter_queue.*.arn, [""]), 0)
}
