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

data "kustomization_build" "secrets-driver" {
  path = "./../../common/secrets-driver/base"
}


resource "kustomization_resource" "secrets-driver" {
  for_each = data.kustomization_build.secrets-driver.ids

  manifest = data.kustomization_build.secrets-driver.manifests[each.value]
}

resource "kubectl_manifest" "secret-class" {
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
      - objectName: "${local.rds_secret}"
        objectType: "secretsmanager"
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
      - objectName: "${local.s3_secret}"
        objectType: "secretsmanager"
        jmesPath:
            - path: "accesskey"
              objectAlias: "access"
            - path: "secretkey"
              objectAlias: "secret"
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
      name: "${local.rds_secret}"
      readOnly: true
    - mountPath: /mnt/aws-store
      name: "${local.s3_secret}"
      readOnly: true
  serviceAccountName: kubeflow-secrets-manager-sa
  volumes:
  - csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: aws-secrets
    name: "${local.rds_secret}"
  - csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: aws-secrets
    name: "${local.s3_secret}"
YAML
}