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
