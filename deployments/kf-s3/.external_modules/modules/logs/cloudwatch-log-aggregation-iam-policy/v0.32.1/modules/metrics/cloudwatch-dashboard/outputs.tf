output "dashboard_arns" {
  description = "A map from name to ARN of the CloudWatch dashboards that were created. The key refers to the name of the dashboard as passed in through var.dashboards."
  value       = { for name, dashboard in aws_cloudwatch_dashboard.dashboard : name => dashboard.dashboard_arn }
}

output "widgets" {
  description = "Output the dashboards input for debugging purposes. This is useful for inspecting all the widget inputs that were passed in to construct the dashboard."
  value       = var.dashboards
}
