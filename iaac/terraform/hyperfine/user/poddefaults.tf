resource "kubectl_manifest" "pipeline-pd" {
  yaml_body = <<YAML
apiVersion: kubeflow.org/v1alpha1
kind: PodDefault
metadata:
  name: access-ml-pipeline
  namespace: ${local.name}
spec:
  desc: Allow access to Kubeflow Pipelines
  selector:
    matchLabels:
      access-ml-pipeline: "true"
  volumes:
    - name: volume-kf-pipeline-token
      projected:
        sources:
          - serviceAccountToken:
              path: token
              expirationSeconds: 7200
              audience: pipelines.kubeflow.org
  volumeMounts:
    - mountPath: /var/run/secrets/kubeflow/pipelines
      name: volume-kf-pipeline-token
      readOnly: true
  env:
    - name: KF_PIPELINES_SA_TOKEN_PATH
      value: /var/run/secrets/kubeflow/pipelines/token
YAML
}

resource "kubectl_manifest" "eviction-pd" {
  yaml_body = <<YAML
apiVersion: kubeflow.org/v1alpha1
kind: PodDefault
metadata:
  name: prevent-eviction
  namespace: ${local.name}
spec:
  desc: prevent eviction
  selector:
    matchLabels:
      prevent-eviction: "true"
  annotations:
    cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
YAML
}

resource "kubectl_manifest" "env-default" {
  yaml_body = <<YAML
apiVersion: "kubeflow.org/v1alpha1"
kind: PodDefault
metadata:
  name: "add-env"
  namespace: ${local.name}
spec:
 desc: "add env"
 selector:
   matchLabels:
     add-env: "true"
 envFrom:
 - configMapRef:
     name: env-config
YAML
}

resource "kubectl_manifest" "config-map" {
  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: env-config
  namespace: ${local.name}
data:
  NAMESPACE: ${local.name}
YAML
}

resource "kubectl_manifest" "ssh-default" {
  yaml_body = <<YAML
apiVersion: "kubeflow.org/v1alpha1"
kind: PodDefault
metadata:
  name: "add-secret-volume"
  namespace: ${local.name}
spec:
 desc: "add secret volume"
 selector:
   matchLabels:
     add-secret-volume: "true"
 volumeMounts:
 - name: secret-volume
   mountPath: /etc/ssh-key
 volumes:
 - name: secret-volume
   secret:
     secretName: ssh-secret-${local.name}
     defaultMode: 256
YAML
}

