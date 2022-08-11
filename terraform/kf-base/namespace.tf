
data "kustomization_build" "namespace" {
  path = "./../../common/kubeflow-namespace/base"
}

data "kustomization_build" "roles" {
  path = "./../../common/kubeflow-roles/base"
}

resource "kustomization_resource" "namespace" {
  for_each = data.kustomization_build.namespace.ids

  manifest = data.kustomization_build.namespace.manifests[each.value]


}


resource "kustomization_resource" "roles" {
  for_each = data.kustomization_build.roles.ids

  manifest = data.kustomization_build.roles.manifests[each.value]
}
