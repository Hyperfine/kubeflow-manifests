
resource "kubectl_manifest" "efs-home" {
  yaml_body = <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "${local.key}-home"
  namespace: ${local.name}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ${var.efs_storage_class_name}
  resources:
    requests:
      storage: 30Gi
YAML
}