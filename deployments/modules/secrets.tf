
locals {
  sa_name = "kf-secrets-manager-sa"
  namespace = "kubeflow"
  kf_secret_names = toset([var.rds_secret_name, var.s3_secret_name])

}

data aws_secretsmanager_secret "kf_secrets" {
  for_each = local.kf_secret_names
  name = each.key
}

resource "aws_iam_role" "kf-irsa" {
  force_detach_policies = true
  name  = "${var.eks_cluster_name}-${local.sa_name}"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17"

    "Statement": [{
      "Action": "sts:AssumeRoleWithWebIdentity"
      "Effect": "Allow"
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_id}"
      }
      "Condition": {
        "StringEquals": {
          "${local.oidc_id}:sub": [
             "system:serviceaccount:${local.namespace}:${local.sa_name}"
            ]
        }
      }
    }]
  })
}


data aws_iam_policy_document "kf-ssm" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = ["kms:Decrypt", "kms:DescribeKey"]
    resources = var.kms_key_ids
  }

  statement {
    effect    = "Allow"
    actions   = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [for k, v in data.aws_secretsmanager_secret.kf_secrets: v.arn]
  }
}

resource aws_iam_policy "kf-ssm" {
  name = "${local.sa_name}-ssm-policy"
  policy = data.aws_iam_policy_document.kf-ssm.json
}

resource aws_iam_role_policy_attachment "kf-secret" {
  role = aws_iam_role.kf-irsa.name
  policy_arn = aws_iam_policy.kf-ssm.arn
}

resource "kubectl_manifest" "kf-irsa" {
  depends_on = [aws_iam_role.kf-irsa]
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${local.sa_name}
  namespace: ${local.namespace}
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.kf-irsa.arn}
YAML
}

resource "kubectl_manifest" "kf-secret-class" {
  depends_on = [kubectl_manifest.kf-irsa]
  yaml_body = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: aws-secrets
  namespace: ${local.namespace}
spec:
  provider: aws
  secretObjects:
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


resource "kubectl_manifest" "kf-secret-pod" {
  depends_on = [kubectl_manifest.kf-secret-class]
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kf-secrets-deployment
  namespace: kubeflow
  labels:
    app: kf-secrets
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kf-secrets
  template:
    metadata:
      labels:
        app: kf-secrets
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
YAML
}
