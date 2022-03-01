
data aws_eks_cluster "cluster" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

locals {
  oidc_id = trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")
  rds_secret = aws_secretsmanager_secret.rds-secret.name
  s3_secret = aws_secretsmanager_secret.s3-secret.name
}

resource "aws_iam_role" "irsa" {
  name  = "${var.cluster_name}-kf-secrets-manager-sa"
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
             "system:serviceaccount:kubeflow:kubeflow-secrets-manager-sa"
            ]
        }
      }
    }]
  })
}

resource aws_iam_role_policy_attachment "secret" {
  role = aws_iam_role.irsa.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource aws_iam_role_policy_attachment "ssm" {
  role = aws_iam_role.irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
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

resource "kubectl_manifest" "secret-class" {
  yaml_body = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: aws-secrets
  namespace: kubeflow
spec:
  parameters:
    objects: "- objectName: \"${local.rds_secret}\"\n  objectType: \"secretsmanager\"\n  jmesPath:\n      - path: \"username\"\n        objectAlias: \"user\"\n      - path: \"password\"\n        objectAlias: \"pass\"\n      - path: \"host\"\n        objectAlias: \"host\"\n      - path: \"database\"\n        objectAlias: \"database\"\n      - path: \"port\"\n        objectAlias: \"port\"\n- objectName: \"${local.s3_secret}\"\n  objectType: \"secretsmanager\"\n  jmesPath:\n      - path: \"accesskey\"\n        objectAlias: \"access\"\n      - path: \"secretkey\"\n        objectAlias: \"secret\"           \n"
  provider: aws
  secretObjects:
  - data:
    - key: username
      objectName: user
    - key: password
      objectName: pass
    - key: host
      objectName: host
    - key: database
      objectName: database
    - key: port
      objectName: port
    secretName: mysql-secret
    type: Opaque
  - data:
    - key: accesskey
      objectName: access
    - key: secretkey
      objectName: secret
    secretName: mlpipeline-minio-artifact
    type: Opaque
YAML
}

resource "kubectl_manifest" "secret-pod" {
  depends_on = [kubectl_manifest.irsa]
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
    - mountPath: /mnt/rds-store
      name: ${local.rds_secret}
      readOnly: true
    - mountPath: /mnt/aws-store
      name: ${local.s3_secret}
      readOnly: true
  serviceAccountName: kubeflow-secrets-manager-sa
  volumes:
  - csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: aws-secrets
    name: ${local.rds_secret}
  - csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: aws-secrets
    name: ${local.s3_secret}
YAML
}