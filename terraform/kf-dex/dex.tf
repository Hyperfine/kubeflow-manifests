data "kustomization_build" "oidc-auth" {
  path = "./../../common/oidc-authservice/base"
}

data "kustomization_build" "dex" {
  path = "./../../common/dex/overlays/istio"
}

resource "kustomization_resource" "oidc-auth" {
  for_each = data.kustomization_build.oidc-auth.ids

  manifest = data.kustomization_build.oidc-auth.manifests[each.value]
}

resource "kustomization_resource" "dex" {
  depends_on = [kustomization_resource.oidc-auth]
  for_each = data.kustomization_build.dex.ids

  manifest = data.kustomization_build.dex.manifests[each.value]
}
