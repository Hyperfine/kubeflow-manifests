

resource "kubectl_manifest" "katib-secret" {
    yaml_body = <<YAML
apiVersion: v1
stringData:
  DB_PASSWORD: ${local.rds_info["password"]}
  DB_USER: ${local.rds_info["username"]}
  KATIB_MYSQL_DB_DATABASE: katib
  KATIB_MYSQL_DB_HOST: ${local.rds_info["host"]}"
  KATIB_MYSQL_DB_PORT: "${local.rds_info["port"]}"
  MYSQL_ROOT_PASSWORD: ${local.rds_info["password"]}
kind: Secret
metadata:
  name: katib-mysql-secrets
  namespace: kubeflow
type: Opaque
YAML
}

data "kubectl_file_documents" "katib" {
  content =file("${path.module}/katib.yaml")
}


resource "kubectl_manifest" "katib" {
    depends_on = [kubectl_manifest.katib-secret]
    for_each  = data.kubectl_file_documents.katib.manifests
    yaml_body = each.value
}
