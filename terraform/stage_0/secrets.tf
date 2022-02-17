data "kustomization_build" "secrets-driver" {
  path = "./common/secrets-driver/base"
}

resource "kustomization_resource" "secrets-driver" {
  for_each = data.kustomization_build.secrets-driver.ids

  manifest = data.kustomization_build.secrets-driver.manifests[each.value]
}