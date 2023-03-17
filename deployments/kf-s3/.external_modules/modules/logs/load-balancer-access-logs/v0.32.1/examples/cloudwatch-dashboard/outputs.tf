output "name" {
  value = var.name
}

output "arns" {
  value = module.dashboard.dashboard_arns
}

output "widgets" {
  value = module.dashboard.widgets
}
