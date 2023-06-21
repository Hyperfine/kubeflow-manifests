terraform {
  required_version = ">= 1.0.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.71"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.13.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}



locals {
  url = "https://${var.subdomain}.${data.aws_route53_zone.top_level.name}"
}



resource "kubernetes_namespace_v1" "auth" {
  metadata {
    name = var.auth_namespace
  }
}

data "aws_iam_policy_document" "ssm" {
  version = "2012-10-17"

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = var.kms_key_arns
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [for k, v in data.aws_secretsmanager_secret.oidc_secrets : v.arn]
  }
}

resource "aws_iam_policy" "oidc-ssm" {
  name   = "${var.eks_cluster_name}-${var.auth_sa_name}-ssm-policy"
  policy = data.aws_iam_policy_document.ssm.json
}

module "dex-irsa" {
  source                     = "git::git@github.com:hyperfine/terraform-aws-eks.git//modules/eks-irsa?ref=v0.48.3"
  kubernetes_namespace       = var.auth_namespace
  kubernetes_service_account = var.auth_sa_name
  irsa_iam_policies          = [aws_iam_policy.oidc-ssm.arn]
  eks_cluster_id             = var.eks_cluster_name

  create_kubernetes_namespace         = false
  create_service_account_secret_token = true
}

locals {
  dex_module_sa = reverse(split("/", module.dex-irsa.service_account))[0] # implicit dependency
}

resource "kubectl_manifest" "oidc-secret-class" {
  yaml_body = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: oidc-secrets
  namespace: "${kubernetes_namespace_v1.auth.metadata[0].name}"
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

resource "kubectl_manifest" "oidc-secret-pod" {
  force_new  = true
  yaml_body  = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-secrets
  namespace: "${kubernetes_namespace_v1.auth.metadata[0].name}"
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
      serviceAccountName: "${local.dex_module_sa}"
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

resource "helm_release" "dex" {
  repository = "https://charts.dexidp.io"
  name       = "dex"
  chart      = "dex"
  version    = var.dex_version
  namespace  = kubernetes_namespace_v1.auth.metadata[0].name

  values = [<<YAML
envVars:
- name: KUBERNETES_POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
envFrom:
- secretRef:
    name: dex-oidc-client
- secretRef:
    name: okta-oidc-secrets
config:
  storage:
    type: kubernetes
    config:
      inCluster: true
  oauth2:
    skipApprovalScreen: true
  web:
    http: 0.0.0.0:5556
  logger:
    level: "debug"
    format: text
  issuer: "${local.url}/dex"
  connectors:
  - type: oidc
    id: okta
    name: Okta
    config:
      insecureSkipEmailVerified: true
      issuer: '{{ .Env.SSO_ISSUER_URL }}'
      clientID: '{{ .Env.SSO_CLIENT_ID }}'
      clientSecret: '{{ .Env.SSO_CLIENT_SECRET }}'
      redirectURI: "${local.url}/dex/callback"
  enablePasswordDB: true
  staticClients:
  - idEnv: OIDC_CLIENT_ID
    redirectURIs: ["/login/oidc"]
    name: 'Dex Login Application'
    secretEnv: OIDC_CLIENT_SECRET
YAML
  ]
}

resource "kubectl_manifest" "virtual" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: dex
  namespace: auth
spec:
  gateways:
  - kubeflow/kubeflow-gateway
  hosts:
  - '*'
  http:
  - match:
    - uri:
        prefix: /dex/
    route:
    - destination:
        host: dex.auth.svc.cluster.local
        port:
          number: 5556
YAML
}
