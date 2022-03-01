data aws_secretsmanager_secret_version "secret" {
  secret_id = var.secret_id
}

locals {
  keys = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)
}

resource "kubectl_manifest" "katib-secret" {
    yaml_body = <<YAML
apiVersion: v1
stringData:
  DB_PASSWORD: ${local.keys["password"]}
  DB_USER: ${local.keys["username"]}
  KATIB_MYSQL_DB_DATABASE: katib
  KATIB_MYSQL_DB_HOST: ${local.keys["host"]}"
  KATIB_MYSQL_DB_PORT: "${local.keys["port"]}"
  MYSQL_ROOT_PASSWORD: ${local.keys["password"]}
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