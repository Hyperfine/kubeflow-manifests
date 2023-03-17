resource "helm_release" "dex" {
  depends_on = [kubectl_manifest.oidc-secret-pod]
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
  depends_on = [helm_release.dex]
    for_each  = data.kubectl_file_documents.oidc.manifests
    yaml_body = each.value
}
