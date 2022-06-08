data "kustomization_build" "oidc-auth" {
  path = "./../../common/oidc-authservice/base"
}

data "kustomization_build" "profiles" {
  path = "./../../apps/profiles/upstream/overlays/kubeflow"
}

resource "kubectl_manifest" "secret" {
  yaml_body = <<YAML
apiVersion: v1
data:
  OIDC_CLIENT_ID: a3ViZWZsb3ctb2lkYy1hdXRoc2VydmljZQ==
  OIDC_CLIENT_SECRET: cFVCbkJPWTgwU25YZ2ppYlRZTTlaV056WTJ4cmVOR1Fvaw==
kind: Secret
metadata:
  name: dex-oidc-client
  namespace: auth
type: Opaque
YAML
}


resource "helm_release" "dex" {
  depends_on = [kubectl_manifest.secret]
  repository = "https://charts.dexidp.io"
  name       = "dex"
  chart      = "dex"
  version    = "0.8.3"
  namespace  = "auth"
  create_namespace = true
  values = [<<YAML
envFrom:
- secretRef:
    name: dex-oidc-client
config:
  storage:
    type: kubernetes
    config:
      inCluster: true
  web:
    http: 0.0.0.0:5556
  logger:
    level: "debug"
    format: text
  issuer: http://platform.hyperfine-dev.io/dex
  connectors:
  - type: oidc
    id: okta
    name: Okta
    config:
      insecureSkipEmailVerified: true
      issuer: https://dev-4870369.okta.com
      clientID: 0oa5bdyi22l49gUwq5d7
      clientSecret: XfuuFuVhJaT9al8PphZJfAmbS0SengbYFywvdyZ6
      redirectURI: http://platform.hyperfine-dev.io/dex/callback
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

resource "kustomization_resource" "oidc-auth" {
  for_each = data.kustomization_build.oidc-auth.ids

  manifest = data.kustomization_build.oidc-auth.manifests[each.value]
}

resource "kustomization_resource" "profiles" {
  for_each = data.kustomization_build.profiles.ids

  manifest = data.kustomization_build.profiles.manifests[each.value]
}
