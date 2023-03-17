output "arn" {
  description = "Amazon Resource Name of the file system."
  value       = module.efs.arn
}

output "id" {
  description = "The ID that identifies the file system (e.g. fs-ccfc0d65)."
  value       = module.efs.id
}

output "dns_name" {
  description = "The DNS name for the filesystem per documented convention: http://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html"
  value       = module.efs.dns_name
}

output "mount_target_ids" {
  description = "The IDs of the mount targets (e.g. fsmt-f9a14450)."
  value       = module.efs.mount_target_ids
}