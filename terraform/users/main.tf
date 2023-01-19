terraform {
  required_providers {
        kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    aws = {
      version = ">= 4.1.0"
    }
  }
}

locals {
  key = var.username
  sa_name = "${var.username}-sa"
}

resource "kubectl_manifest" "config" {
        yaml_body = <<YAML
apiVersion: v1
data:
  profile-name: ${local.key}
  user: "${local.key}@hyperfine.io"
kind: ConfigMap
metadata:
  name: default-install-config-${local.key}
YAML
}

resource "kubectl_manifest" "profile" {
    yaml_body = <<YAML
apiVersion: kubeflow.org/v1beta1
kind: Profile
metadata:
  name: ${local.key}
spec:
  owner:
    kind: User
    name: "${local.key}@hyperfine.io"
YAML
}

resource "time_sleep" "wait_for_namespace" {
  depends_on = [kubectl_manifest.profile]
  create_duration = '30s'
}


resource "kubectl_manifest" "secret-class" {
    depends_on = [time_sleep.wait_for_namespace]

  yaml_body = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: aws-secrets
  namespace: ${local.key}
spec:
  provider: aws
  secretObjects:
  - secretName: ssh-secret-${local.key}
    type: Opaque
    data:
    - objectName: "${local.key}"
      key: private
    - objectName: "${local.key}.pub"
      key: public
  - secretName: mysql-secret
    type: Opaque
    data:
    - objectName: "user"
      key: username
    - objectName: "pass"
      key: password
    - objectName: "host"
      key: host
    - objectName: "database"
      key: database
    - objectName: "port"
      key: port
  - secretName: mlpipeline-minio-artifact
    type: Opaque
    data:
    - objectName: "access"
      key: accesskey
    - objectName: "secret"
      key: secretkey
  parameters:
    objects: |
      - objectName: "${var.ssh_key_secret_name}"
        objectType: "secretsmanager"
        objectAlias: "${local.key}-ssh"
        objectVersionLabel: "AWSCURRENT"
        jmesPath:
            - path: "private"
              objectAlias: "${local.key}"
            - path: "public"
              objectAlias: "${local.key}.pub"
      - objectName: "${var.rds_secret_name}"
        objectType: "secretsmanager"
        objectAlias: "rds-secret"
        objectVersionLabel: "AWSCURRENT"
        jmesPath:
            - path: "username"
              objectAlias: "user"
            - path: "password"
              objectAlias: "pass"
            - path: "host"
              objectAlias: "host"
            - path: "database"
              objectAlias: "database"
            - path: "port"
              objectAlias: "port"
      - objectName: "${var.s3_secret_name}"
        objectType: "secretsmanager"
        objectAlias: "s3-secret"
        objectVersionLabel: "AWSCURRENT"
        jmesPath:
            - path: "accesskey"
              objectAlias: "access"
            - path: "secretkey"
              objectAlias: "secret"
YAML
}

resource "kubectl_manifest" "ssh-default" {
    depends_on = [time_sleep.wait_for_namespace]

  yaml_body = <<YAML
apiVersion: "kubeflow.org/v1alpha1"
kind: PodDefault
metadata:
  name: "add-secret-volume"
  namespace: ${local.key}
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
     secretName: ssh-secret-${local.key}
     defaultMode: 256
YAML
}


resource "kubectl_manifest" "annotation-default" {
    depends_on = [time_sleep.wait_for_namespace]

  yaml_body = <<YAML
apiVersion: "kubeflow.org/v1alpha1"
kind: PodDefault
metadata:
  name: "add-iam-role"
  namespace: ${local.key}
spec:
 desc: "add iam-role"
 selector:
   matchLabels:
     add-iam-role: "true"
 annotations:
   iam.amazonaws.com/role: arn:aws:iam::369500102003:role/hyperfine-dev-eks-cluster-kf-dl-dl-data-lake-sa
YAML
}

resource "kubectl_manifest" "config-map" {
    depends_on = [time_sleep.wait_for_namespace]

  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: env-config
  namespace: ${local.key}
data:
  NAMESPACE: ${local.key}
YAML
}

resource "kubectl_manifest" "env-default" {
    depends_on = [time_sleep.wait_for_namespace]

  yaml_body = <<YAML
apiVersion: "kubeflow.org/v1alpha1"
kind: PodDefault
metadata:
  name: "add-env"
  namespace: ${local.key}
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

resource "kubectl_manifest" "secret-pod" {
  depends_on = [kubectl_manifest.secret-class]
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kf-secrets-${local.key}-deployment
  namespace: ${local.key}
  labels:
    app: kf-secrets-${local.key}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kf-secrets-${local.key}
  template:
    metadata:
      labels:
        app: kf-secrets-${local.key}
    spec:
      containers:
      - image: k8s.gcr.io/e2e-test-images/busybox:1.29
        command:
        - "/bin/sleep"
        - "10000"
        name: secrets
        volumeMounts:
        - mountPath: "/mnt/rds-store"
          name: "${var.rds_secret_name}"
          readOnly: true
        - mountPath: "/mnt/aws-store"
          name: "${var.s3_secret_name}"
          readOnly: true
        - mountPath: "/mnt/ssh-store"
          name: "${var.ssh_key_secret_name}"
          readOnly: true
      serviceAccountName: ${local.sa_name}
      volumes:
      - csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: aws-secrets
        name: "${var.rds_secret_name}"
      - csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: aws-secrets
        name: "${var.s3_secret_name}"
      - csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: aws-secrets
        name: "${var.ssh_key_secret_name}"

YAML
}
