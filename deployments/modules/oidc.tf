locals {
  oidc_sa_name = "oidc-secrets-manager-sa"
  auth_namespace = "auth"
}


resource "aws_iam_role" "oidc-irsa" {
  force_detach_policies = true
  name  = "${var.eks_cluster_name}-${local.oidc_sa_name}"
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
             "system:serviceaccount:${local.auth_namespace}:${local.oidc_sa_name}",
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
    resources = [for k, v in data.aws_secretsmanager_secret.oidc_secrets: v.arn]
  }
}

resource aws_iam_policy "oidc-ssm" {
  name = "${local.oidc_sa_name}-ssm-policy"
  policy = data.aws_iam_policy_document.ssm.json
}

resource aws_iam_role_policy_attachment "oidc-secret" {
  role = aws_iam_role.oidc-irsa.name
  policy_arn = aws_iam_policy.oidc-ssm.arn
}

resource "kubernetes_namespace" "auth" {
  metadata {
    name = "auth"
  }
}

resource "kubectl_manifest" "oidc-auth-service-account" {
  depends_on = [kubernetes_namespace.auth]
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${local.oidc_sa_name}
  namespace: ${local.auth_namespace}
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.oidc-irsa.arn}
YAML
}

resource "kubectl_manifest" "oidc-service-account" {

  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${local.oidc_sa_name}
  namespace: istio-system
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.oidc-irsa.arn}
YAML
}


resource "kubectl_manifest" "oidc-secret-class" {
  depends_on = [kubernetes_namespace.auth]

  yaml_body = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: oidc-secrets
  namespace: ${local.auth_namespace}
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


resource "kubectl_manifest" "auth-secret-class" {
    depends_on = [kubernetes_namespace.auth]

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


resource "kubectl_manifest" "oidc-secret-pod" {
    depends_on = [kubernetes_namespace.auth]
  force_new = true
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-secrets
  namespace: auth
  labels:
    app: auth-secrets-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auth-secrets-deployment
  template:
    metadata:
      labels:
        app: auth-secrets-deployment
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
      serviceAccountName: ${local.oidc_sa_name}
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


resource "kubectl_manifest" "authservice-secret-pod" {
  depends_on = [kubectl_manifest.auth-secret-class]
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: authservice-secrets-deployment
  namespace: istio-system
  labels:
    app: authservice-secrets
spec:
  replicas: 1
  selector:
    matchLabels:
      app: authservice-secrets
  template:
    metadata:
      labels:
        app: authservice-secrets
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

resource "kubectl_manifest" "oidc_auth_config" {
  yaml_body = <<YAML
apiVersion: v1
data:
  OIDC_AUTH_URL: /dex/auth
  OIDC_PROVIDER: "${local.url}/dex"
  OIDC_SCOPES: profile email groups
  PORT: '"8080"'
  REDIRECT_URL: /login/oidc
  SKIP_AUTH_URI: /dex
  STORE_PATH: /var/lib/authservice/data.db
  USERID_CLAIM: email
  USERID_HEADER: kubeflow-userid
  USERID_PREFIX: ""
kind: ConfigMap
metadata:
  name: oidc-authservice-parameters
  namespace: istio-system
YAML
}
