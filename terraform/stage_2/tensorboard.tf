data "kustomization_build" "tb_app" {
  path = "./apps/tensorboard/tensorboards-web-app/upstream/overlays/istio"
}
data "kustomization_build" "tb_controller" {
  path = "./apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow"
}

resource "kustomization_resource" "tb_app" {
  for_each = data.kustomization_build.tb_app.ids

  manifest = data.kustomization_build.tb_app.manifests[each.value]
}
resource "kustomization_resource" "tb_controller" {
  for_each = data.kustomization_build.tb_controller.ids

  manifest = data.kustomization_build.tb_controller.manifests[each.value]
}