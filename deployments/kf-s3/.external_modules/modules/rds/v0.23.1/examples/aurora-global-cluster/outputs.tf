output "cluster_endpoint" {
  value = module.aurora_global_cluster_primary.cluster_endpoint
}

output "instance_endpoints" {
  value = module.aurora_global_cluster_primary.instance_endpoints
}

output "replica_cluster_endpoint" {
  value = module.aurora_replica.cluster_endpoint
}

output "replica_instance_endpoints" {
  value = module.aurora_replica.instance_endpoints
}

output "port" {
  value = module.aurora_global_cluster_primary.port
}
