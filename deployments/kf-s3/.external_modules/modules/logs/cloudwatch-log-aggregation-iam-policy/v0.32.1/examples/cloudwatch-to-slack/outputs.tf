output "instance_id" {
  value = length(aws_instance.example) > 0 ? aws_instance.example[0].id : null
}

output "instance_public_ip" {
  value = length(aws_instance.example) > 0 ? aws_instance.example[0].public_ip : null
}
