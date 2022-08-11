resource "kubectl_manifest" "katib_deployment" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: katib-db-manager
  name: katib-db-manager
  namespace: kubeflow
spec:
  replicas: 1
  selector:
    matchLabels:
      app: katib-db-manager
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "false"
      labels:
        app: katib-db-manager
    spec:
      containers:
      - command:
        - ./katib-db-manager
        env:
        - name: DB_NAME
          value: mysql
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              key: username
              name: mysql-secret
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              key: password
              name: mysql-secret
        - name: KATIB_MYSQL_DB_DATABASE
          valueFrom:
            secretKeyRef:
              key: database
              name: mysql-secret
        - name: KATIB_MYSQL_DB_HOST
          valueFrom:
            secretKeyRef:
              key: host
              name: mysql-secret
        - name: KATIB_MYSQL_DB_PORT
          valueFrom:
            secretKeyRef:
              key: port
              name: mysql-secret
        image: docker.io/kubeflowkatib/katib-db-manager:v0.11.1
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:6789
          failureThreshold: 5
          initialDelaySeconds: 10
          periodSeconds: 60
        name: katib-db-manager
        ports:
        - containerPort: 6789
          name: api
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:6789
          initialDelaySeconds: 5
YAML
}

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
