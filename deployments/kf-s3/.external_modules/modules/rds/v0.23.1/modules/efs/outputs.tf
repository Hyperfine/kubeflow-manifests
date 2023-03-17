output "arn" {
  description = "Amazon Resource Name of the file system."
  value       = aws_efs_file_system.this.arn
}

output "id" {
  description = "The ID that identifies the file system (e.g. fs-ccfc0d65)."
  value       = aws_efs_file_system.this.id
}

output "security_group_id" {
  description = "The IDs of the security groups created for the file system."
  value       = aws_security_group.this.id
}

output "dns_name" {
  description = "The DNS name for the filesystem per documented convention: http://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html"
  value       = aws_efs_file_system.this.dns_name
}

output "mount_target_ids" {
  description = "The IDs of the mount targets (e.g. fsmt-f9a14450)."
  value       = coalescelist(aws_efs_mount_target.this.*.id, [""])
}

output "access_point_ids" {
  description = "A map of EFS access point names to the IDs of the access point (e.g. fsap-52a643fb) for that name."
  value = {
    for name, _ in var.efs_access_points :
    name => aws_efs_access_point.this[name].id
  }
}
