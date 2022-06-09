locals {
  sa_name = "okta-secrets-manager-sa"
  namespace = "auth"
}

resource "aws_iam_role" "irsa" {
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
             "system:serviceaccount:${local.namespace}:${local.sa_name}",
             "system:serviceaccount:istio-system:oidc-secrets-manager-sa"

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
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [for k, v in data.aws_secretsmanager_secret.secrets: v.arn]
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

resource "kubectl_manifest" "okta-service-account" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${local.sa_name}
  namespace: ${local.namespace}
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.irsa.arn}
YAML
}

resource "kubectl_manifest" "oidc-service-account" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: oidc-secrets-manager-sa
  namespace: istio-system
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.irsa.arn}
YAML
}


resource "kubectl_manifest" "secret-class" {
  yaml_body = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: oidc-secrets
  namespace: ${local.namespace}
spec:
  provider: aws
  secretObjects:
  - secretName: okta-oidc-secrets
    type: Opaque
    data:
    - objectName: "sso_client_id"
      key: SSO_CLIENT_ID
    - objectName: "sso_client_secret"
      key: SSO_CLIENT_SECRET
    - objectName: "sso_issuer_url"
      key: SSO_ISSUER_URL
  - secretName: dex-oidc-client
    type: Opaque
    data:
    - objectName: "auth_client_id"
      key: OIDC_CLIENT_ID
    - objectName: "auth_client_secret"
      key: OIDC_CLIENT_SECRET
  parameters:
    objects: |
      - objectName: "${var.okta_secret_name}"
        objectType: "secretsmanager"
        objectAlias: "okta-secret"
        objectVersionLabel: "AWSCURRENT"
        jmesPath:
            - path: "okta_client_id"
              objectAlias: "sso_client_id"
            - path: "okta_client_secret"
              objectAlias: "sso_client_secret"
            - path: "okta_issuer_url"
              objectAlias: "sso_issuer_url"
      - objectName: "${var.oidc_secret_name}"
        objectType: "secretsmanager"
        objectAlias: "oidc-secret"
        objectVersionLabel: "AWSCURRENT"
        jmesPath:
            - path: "auth_client_id"
              objectAlias: "auth_client_id"
            - path: "auth_client_secret"
              objectAlias: "auth_client_secret"
YAML
}

resource "kubectl_manifest" "secret-pod" {
  depends_on = [kubectl_manifest.secret-class]
  yaml_body = <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: okta-secrets-pod
  namespace: auth
spec:
  containers:
  - image: k8s.gcr.io/e2e-test-images/busybox:1.29
    command:
    - "/bin/sleep"
    - "10000"
    name: secrets
    volumeMounts:
    - mountPath: "/mnt/okta-store"
      name: "${var.okta_secret_name}"
      readOnly: true
    - mountPath: "/mnt/oidc-store"
      name: "${var.oidc_secret_name}"
      readOnly: true
  serviceAccountName: ${local.sa_name}
  volumes:
  - csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: oidc-secrets
    name: "${var.oidc_secret_name}"
  - csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: oidc-secrets
    name: "${var.okta_secret_name}"
YAML
}



resource "kubectl_manifest" "auth-secret-class" {
  yaml_body = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: authservice-secrets
  namespace: istio-system
spec:
  provider: aws
  secretObjects:
  - secretName: oidc-authservice-client
    type: Opaque
    data:
    - objectName: "auth_client_id"
      key: CLIENT_ID
    - objectName: "auth_client_secret"
      key: CLIENT_SECRET
  parameters:
    objects: |
      - objectName: "${var.oidc_secret_name}"
        objectType: "secretsmanager"
        objectAlias: "oidc-secret"
        objectVersionLabel: "AWSCURRENT"
        jmesPath:
            - path: "auth_client_id"
              objectAlias: "auth_client_id"
            - path: "auth_client_secret"
              objectAlias: "auth_client_secret"
YAML
}

resource "kubectl_manifest" "authservice-secret-pod" {
  depends_on = [kubectl_manifest.auth-secret-class]
  yaml_body = <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: authservice-secrets-pod
  namespace: istio-system
spec:
  containers:
  - image: k8s.gcr.io/e2e-test-images/busybox:1.29
    command:
    - "/bin/sleep"
    - "10000"
    name: secrets
    volumeMounts:
    - mountPath: "/mnt/auth-store"
      name: "${var.oidc_secret_name}"
      readOnly: true
  serviceAccountName: oidc-secrets-manager-sa
  volumes:
  - csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: authservice-secrets
    name: "${var.oidc_secret_name}"
YAML
}
