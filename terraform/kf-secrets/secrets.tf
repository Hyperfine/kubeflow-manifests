locals {
  sa_name = "kubeflow-secrets-manager-sa"
}

resource "aws_iam_role" "irsa" {
  force_detach_policies = true
  name  = "${var.eks_cluster_name}-kf-secrets-manager-sa"
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
             "system:serviceaccount:kubeflow:${local.sa_name}"
            ]
        }
      }
    }]
  })
}

data aws_iam_policy_document "ssm" {
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
    resources = [data.aws_secretsmanager_secret.rds.arn]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [data.aws_secretsmanager_secret.s3.arn]
  }
}

resource aws_iam_policy "ssm" {
  name = "${local.sa_name}-ssm-policy"
  policy = data.aws_iam_policy_document.ssm.json
}

resource aws_iam_role_policy_attachment "secret" {
  role = aws_iam_role.irsa.name
  policy_arn = aws_iam_policy.ssm.arn
}

resource aws_kms_grant "grant" {
  for_each = toset(var.kms_key_ids)
  name = "${local.sa_name}-ssm-grant"
  grantee_principal = aws_iam_role.irsa.arn
  key_id = each.value
  operations = ["Decrypt", "DescribeKey"]
}

resource "kubectl_manifest" "irsa" {
    yaml_body = yamlencode({
  "apiVersion": "v1"
  "kind": "ServiceAccount"
  "metadata": {
      "name": "kubeflow-secrets-manager-sa",
      "namespace": "kubeflow"
      "annotations": {
        "eks.amazonaws.com/role-arn": aws_iam_role.irsa.arn
      }
  }
  })
}

resource "helm_release" "secrets" {
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  name       = "secrets-store-csi-driver"
  chart      = "secrets-store-csi-driver"
  version    = var.secret_driver_version
  namespace  = "kube-system"
}

data "kubectl_file_documents" "aws" {
  content =file("${path.module}/aws.yaml")
}
resource "kubectl_manifest" "aws" {
    for_each  = data.kubectl_file_documents.aws.manifests
    yaml_body = each.value
}

resource "kubectl_manifest" "secret-class" {
  depends_on = [helm_release.secrets]
  yaml_body = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: aws-secrets
  namespace: kubeflow
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

resource "kubectl_manifest" "secret-pod" {
  depends_on = [kubectl_manifest.secret-class]
  yaml_body = <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: kubeflow-secrets-pod
  namespace: kubeflow
spec:
  containers:
  - image: public.ecr.aws/xray/aws-xray-daemon:latest
    name: secrets
    volumeMounts:
    - mountPath: "/mnt/rds-store"
      name: "${var.rds_secret_name}"
      readOnly: true
    - mountPath: "/mnt/aws-store"
      name: "${var.s3_secret_name}"
      readOnly: true
  serviceAccountName: "${local.sa_name}"
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