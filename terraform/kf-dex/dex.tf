data "kustomization_build" "oidc-auth" {
  path = "./../../common/oidc-authservice/base"
}

data "kustomization_build" "profiles" {
  path = "./../../apps/profiles/upstream/overlays/kubeflow"
}


resource "helm_release" "dex" {
  repository = "https://charts.dexidp.io"
  name       = "dex"
  chart      = "dex"
  version    = "0.8.3"
  namespace  = "dex"
  create_namespace = true
  values = [<<YAML
config:
  storage:
    type: memory
  issuer: asdf

  connectors:
  - type: oidc
    id: okta
    name: Okta
    config:
      # Canonical URL of the provider, also used for configuration discovery.
      # This value MUST match the value returned in the provider config discovery.
      #
      # See: https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig
      issuer: https://accounts.google.com

      # Connector config values starting with a "$" will read from the environment.
      clientID: $GOOGLE_CLIENT_ID
      clientSecret: $GOOGLE_CLIENT_SECRET

      # Dex's issuer URL + "/callback"
      redirectURI: http://127.0.0.1:5556/callback
YAML
  ]
}


resource "kustomization_resource" "oidc-auth" {
  for_each = data.kustomization_build.oidc-auth.ids

  manifest = data.kustomization_build.oidc-auth.manifests[each.value]
}



resource "kustomization_resource" "profiles" {
  for_each = data.kustomization_build.profiles.ids

  manifest = data.kustomization_build.profiles.manifests[each.value]
}

