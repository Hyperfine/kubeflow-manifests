data "kustomization_build" "oidc-auth" {
  path = "./../../common/oidc-authservice/base"
}

data "kustomization_build" "dex" {
  path = "./../../common/dex/overlays/istio"
}

data "kustomization_build" "profiles" {
  path = "./../../apps/profiles/upstream/overlays/kubeflow"
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


resource "kustomization_resource" "profiles" {
  for_each = data.kustomization_build.profiles.ids

  manifest = data.kustomization_build.profiles.manifests[each.value]
}

