data aws_s3_bucket "bucket" {
  bucket = var.bucket
}

data aws_secretsmanager_secret_version "pipe-secret" {
  secret_id = var.secret_id
}

locals {
  pipe-keys = jsondecode(data.aws_secretsmanager_secret_version.pipe-secret.secret_string)
}

data "kubectl_file_documents" "pipeline" {
  content =file("./.deploy/terraform/stage_2/pipeline.yaml")
}

data "kubectl_file_documents" "pipeline-config" {
  content =<<YAML
apiVersion: v1
data:
  ConMaxLifeTimeSec: "120"
  appName: pipeline
  appVersion: 1.5.1
  autoUpdatePipelineDefaultVersion: "true"
  bucketName: ${data.aws_s3_bucket.bucket.bucket}
  cacheDb: cachedb
  cacheImage: gcr.io/google-containers/busybox
  cronScheduleTimezone: UTC
  dbHost: ${local.pipe-keys["host"]}
  dbPort: "${local.pipe-keys["port"]}"
  minioServiceHost: s3.amazonaws.com
  minioServiceRegion: ${var.region}
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
---
apiVersion: v1
data:
  config: |
    {
    artifactRepository:
    {
        s3: {
            bucket: ${data.aws_s3_bucket.bucket.bucket},
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

resource "kubectl_manifest" "pipeline-config" {
    for_each  = data.kubectl_file_documents.pipeline-config.manifests
    yaml_body = each.value
}

resource "kubectl_manifest" "pipeline" {
  depends_on = [kubectl_manifest.pipeline-config]
    for_each  = data.kubectl_file_documents.pipeline.manifests
    yaml_body = each.value
}
