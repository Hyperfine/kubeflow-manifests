data "kustomization_build" "jupyter_app" {
  path = "./apps/jupyter/jupyter-web-app/upstream/overlays/istio"
}
data "kustomization_build" "jupyter_controller" {
  path = "./apps/jupyter/notebook-controller/upstream/overlays/kubeflow"
}

resource "kustomization_resource" "jupyter_app" {
  for_each = data.kustomization_build.jupyter_app.ids

  manifest = data.kustomization_build.jupyter_app.manifests[each.value]
}
resource "kustomization_resource" "jupyter_controller" {
  for_each = data.kustomization_build.jupyter_controller.ids

  manifest = data.kustomization_build.jupyter_controller.manifests[each.value]
}
