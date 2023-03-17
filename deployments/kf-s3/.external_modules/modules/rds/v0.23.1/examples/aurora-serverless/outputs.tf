output "cluster_endpoint" {
  value = module.aurora_serverless.cluster_endpoint
}

output "instance_endpoints" {
  value = module.aurora_serverless.instance_endpoints
}

output "port" {
  value = module.aurora_serverless.port
}

output "instance_ids" {
  value = module.aurora_serverless.instance_ids
}
