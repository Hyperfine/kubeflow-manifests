locals {
  url = "http://${var.subdomain}.${data.aws_route53_zone.top_level.name}"
}

data "kustomization_build" "profiles" {
  path = "./../../apps/profiles/upstream/overlays/kubeflow"
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

resource "helm_release" "dex" {
  depends_on = [kubectl_manifest.secret-pod]
  repository = "https://charts.dexidp.io"
  name       = "dex"
  chart      = "dex"
  version    = var.dex_version
  namespace  = "auth"
  create_namespace = true
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

data "kubectl_file_documents" "oidc" {
  content =file("${path.module}/oidc.yaml")
}

resource "kubectl_manifest" "oidc" {
  depends_on = [kubectl_manifest.authservice-secret-pod]
    for_each  = data.kubectl_file_documents.oidc.manifests
    yaml_body = each.value
}

resource "kustomization_resource" "profiles" {
  for_each = data.kustomization_build.profiles.ids

  manifest = data.kustomization_build.profiles.manifests[each.value]
}




resource "kubectl_manifest" "dex_ingress" {
yaml_body =  <<YAML
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: "${var.acm_certificate}"
    external-dns.alpha.kubernetes.io/hostname: "${var.subdomain}.${data.aws_route53_zone.top_level.name}"
  name: istio-ingress
  namespace: istio-system
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: istio-ingressgateway
          servicePort: 80
        path: /*
YAML
}

