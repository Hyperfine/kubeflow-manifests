output "cluster_endpoint_1" {
  value = module.aurora_global_cluster_primary.cluster_endpoint
}

output "instance_endpoints_1" {
  value = module.aurora_global_cluster_primary.instance_endpoints
}

output "port_1" {
  value = module.aurora_global_cluster_primary.port
}
