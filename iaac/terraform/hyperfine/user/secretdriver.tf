
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
      serviceAccountName: ${local.module_sa}
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
