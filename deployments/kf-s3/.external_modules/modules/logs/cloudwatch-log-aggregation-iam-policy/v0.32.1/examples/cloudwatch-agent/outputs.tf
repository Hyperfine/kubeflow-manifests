output "instance_id_with_logs_and_metrics" {
  value = module.example_instance_with_logs_and_metrics.id
}

output "public_ip_with_logs_and_metrics" {
  value = module.example_instance_with_logs_and_metrics.public_ip
}

output "instance_id_no_metrics" {
  value = module.example_instance_no_metrics.id
}

output "public_ip_no_metrics" {
  value = module.example_instance_no_metrics.public_ip
}

output "instance_id_no_cpu_metrics" {
  value = module.example_instance_no_cpu_metrics.id
}

output "public_ip_no_cpu_metrics" {
  value = module.example_instance_no_cpu_metrics.public_ip
}

output "instance_id_no_mem_metrics" {
  value = module.example_instance_no_mem_metrics.id
}

output "public_ip_no_mem_metrics" {
  value = module.example_instance_no_mem_metrics.public_ip
}

output "instance_id_no_disk_metrics" {
  value = module.example_instance_no_disk_metrics.id
}

output "public_ip_no_disk_metrics" {
  value = module.example_instance_no_disk_metrics.public_ip
}
