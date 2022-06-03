data "kubectl_file_documents" "pipeline" {
  content =file("${path.module}/pipeline.yaml")
}

resource "kubectl_manifest" "pipeline-install-config" {
  yaml_body = <<YAML
apiVersion: v1
data:
  ConMaxLifeTimeSec: "120"
  appName: pipeline
  appVersion: 1.5.1
  autoUpdatePipelineDefaultVersion: "true"
  bucketName: ${var.bucket}
  cacheDb: cachedb
  cacheImage: gcr.io/google-containers/busybox
  cronScheduleTimezone: UTC
  dbHost: ${local.rds_info["host"]}
  dbPort: "${local.rds_info["port"]}"
  minioServiceHost: s3.amazonaws.com
  minioServiceRegion: ${var.aws_region}
  mlmdDb: metadb
  pipelineDb: mlpipeline
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/component: ml-pipeline
    app.kubernetes.io/name: kubeflow-pipelines
    application-crd-id: kubeflow-pipelines
  name: pipeline-install-config
  namespace: kubeflow
YAML
}


# https://github.com/kubeflow/manifests/issues/2061 minio proxy access
resource "kubectl_manifest" "pipeline-config" {
  yaml_body = <<YAML
apiVersion: v1
data:
  config: |
    {
    artifactRepository:
    {
        s3: {
            bucket: ${var.bucket},
            keyPrefix: artifacts,
            endpoint: s3.amazonaws.com,
            insecure: true,
            accessKeySecret: {
                name: mlpipeline-minio-artifact,
                key: accesskey
            },
            secretKeySecret: {
                name: mlpipeline-minio-artifact,
                key: secretkey
            }
        },
        archiveLogs: true
    }
    }
kind: ConfigMap
metadata:
  labels:
    application-crd-id: kubeflow-pipelines
  name: workflow-controller-configmap
  namespace: kubeflow
YAML
}

resource "kubectl_manifest" "pipeline" {
  depends_on = [kubectl_manifest.pipeline-config]
    for_each  = data.kubectl_file_documents.pipeline.manifests
    yaml_body = each.value
}

resource "kubectl_manifest" "deploy" {
  depends_on = [kubectl_manifest.pipeline]
  yaml_body = <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: cache-server
    app.kubernetes.io/component: ml-pipeline
    app.kubernetes.io/name: kubeflow-pipelines
    application-crd-id: kubeflow-pipelines
  name: cache-server
  namespace: kubeflow
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cache-server
      app.kubernetes.io/component: ml-pipeline
      app.kubernetes.io/name: kubeflow-pipelines
      application-crd-id: kubeflow-pipelines
  template:
    metadata:
      labels:
        app: cache-server
        app.kubernetes.io/component: ml-pipeline
        app.kubernetes.io/name: kubeflow-pipelines
        application-crd-id: kubeflow-pipelines
    spec:
      containers:
      - args:
        - --db_driver=$(DBCONFIG_DRIVER)
        - --db_host=$(DBCONFIG_HOST_NAME)
        - --db_port=$(DBCONFIG_PORT)
        - --db_name=$(DBCONFIG_DB_NAME)
        - --db_user=$(DBCONFIG_USER)
        - --db_password=$(DBCONFIG_PASSWORD)
        - --namespace_to_watch=$(NAMESPACE_TO_WATCH)
        env:
        - name: NAMESPACE_TO_WATCH
          value: ""
        - name: CACHE_IMAGE
          valueFrom:
            configMapKeyRef:
              key: cacheImage
              name: pipeline-install-config
        - name: DBCONFIG_DRIVER
          value: mysql
        - name: DBCONFIG_DB_NAME
          valueFrom:
            configMapKeyRef:
              key: cacheDb
              name: pipeline-install-config
        - name: DBCONFIG_HOST_NAME
          valueFrom:
            configMapKeyRef:
              key: dbHost
              name: pipeline-install-config
        - name: DBCONFIG_PORT
          valueFrom:
            configMapKeyRef:
              key: dbPort
              name: pipeline-install-config
        - name: DBCONFIG_USER
          valueFrom:
            secretKeyRef:
              key: username
              name: mysql-secret
        - name: DBCONFIG_PASSWORD
          valueFrom:
            secretKeyRef:
              key: password
              name: mysql-secret
        image: gcr.io/ml-pipeline/cache-server:1.5.1
        imagePullPolicy: Always
        name: server
        ports:
        - containerPort: 8443
          name: webhook-api
      serviceAccountName: kubeflow-pipelines-cache
      volumes:
      - name: webhook-tls-certs
        secret:
          secretName: webhook-server-tls
EOF
}