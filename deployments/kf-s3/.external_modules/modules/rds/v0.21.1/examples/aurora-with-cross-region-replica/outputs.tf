output "cluster_endpoint_primary" {
  value = module.aurora_primary.cluster_endpoint
}

output "instance_endpoints_primary" {
  value = module.aurora_primary.instance_endpoints
}

output "port_primary" {
  value = module.aurora_primary.port
}

output "instance_ids_primary" {
  value = module.aurora_primary.instance_ids
}

output "cluster_endpoint_replica" {
  value = module.aurora_replica.cluster_endpoint
}

output "instance_endpoints_replica" {
  value = module.aurora_replica.instance_endpoints
}

output "port_replica" {
  value = module.aurora_replica.port
}

output "instance_ids_replica" {
  value = module.aurora_replica.instance_ids
}
