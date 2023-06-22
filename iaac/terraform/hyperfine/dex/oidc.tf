

module "auth-irsa" {
  source                     = "git::git@github.com:hyperfine/terraform-aws-eks.git//modules/eks-irsa?ref=v0.48.3"
  kubernetes_namespace       = "istio-system"
  kubernetes_service_account = "oidc-secrets-manager-sa"
  irsa_iam_policies          = [aws_iam_policy.oidc-ssm.arn]
  eks_cluster_id             = var.eks_cluster_name

  create_kubernetes_namespace         = false
  create_service_account_secret_token = true
}

locals {
  auth_module_sa = reverse(split("/", module.auth-irsa.service_account))[0] # implicit dependency
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
  yaml_body  = <<YAML
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
      serviceAccountName: "${local.auth_module_sa}"
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
  AUTHSERVICE_URL_PREFIX: /authservice/
  OIDC_AUTH_URL: /dex/auth
  OIDC_PROVIDER: "${local.url}/dex"
  OIDC_SCOPES: profile email groups
  PORT: '"8080"'
  SKIP_AUTH_URLS: /dex
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

resource "helm_release" "oidc" {
  name      = "auth-service"
  namespace = "istio-system"
  chart     = "../../charts/common/oidc-authservice"

  values = [<<YAML
configMap: |
  apiVersion: v1
  data:
    AUTHSERVICE_URL_PREFIX: /authservice/
    OIDC_AUTH_URL: /dex/auth
    OIDC_PROVIDER: "${local.url}/dex"
    OIDC_SCOPES: profile email groups
    PORT: '"8080"'
    SKIP_AUTH_URLS: /dex
    STORE_PATH: /var/lib/authservice/data.db
    USERID_CLAIM: email
    USERID_HEADER: kubeflow-userid
    USERID_PREFIX: ""
  kind: ConfigMap
  metadata:
    name: oidc-authservice-parameters
    namespace: istio-system
YAML
  ]
}

