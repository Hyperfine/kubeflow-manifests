data "kustomization_build" "istio_crds" {
  path = "./common/istio-1-9/istio-crds/base"
}
data "kustomization_build" "istio_ns" {
  path = "./common/istio-1-9/istio-namespace/base"
}
data "kustomization_build" "istio_install" {
  path = "./common/istio-1-9/istio-install/base"
}
data "kustomization_build" "resources" {
  path = "./common/istio-1-9/kubeflow-istio-resources/base"
}

resource "kustomization_resource" "istio_crds" {
  for_each = data.kustomization_build.istio_crds.ids

  manifest = data.kustomization_build.istio_crds.manifests[each.value]
}

resource "kustomization_resource" "istio_ns" {
  for_each = data.kustomization_build.istio_ns.ids

  manifest = data.kustomization_build.istio_ns.manifests[each.value]
}
resource "kustomization_resource" "istio_install" {
  for_each = data.kustomization_build.istio_install.ids

  manifest = data.kustomization_build.istio_install.manifests[each.value]
}

resource "kustomization_resource" "resources" {
  for_each = data.kustomization_build.resources.ids

  manifest = data.kustomization_build.resources.manifests[each.value]
}