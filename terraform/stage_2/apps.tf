data "kustomization_build" "kfserving" {
  path = "./apps/kfserving/upstream/overlays/kubeflow"
}

data "kustomization_build" "centraldashboard" {
  path = "./apps/centraldashboard/upstream/overlays/istio"
}

data "kustomization_build" "admission" {
  path = "./apps/admission-webhook/upstream/overlays/cert-manager"
}

data "kustomization_build" "volumes" {
  path = "./apps/volumes-web-app/upstream/overlays/istio"
}


resource "kustomization_resource" "admission" {
  for_each = data.kustomization_build.admission.ids

  manifest = data.kustomization_build.admission.manifests[each.value]
}

resource "kustomization_resource" "kfserving" {
  for_each = data.kustomization_build.kfserving.ids

  manifest = data.kustomization_build.kfserving.manifests[each.value]
}

resource "kustomization_resource" "volumes" {
  for_each = data.kustomization_build.volumes.ids

  manifest = data.kustomization_build.volumes.manifests[each.value]
}

resource "kustomization_resource" "centraldashboard" {
  for_each = data.kustomization_build.centraldashboard.ids

  manifest = data.kustomization_build.centraldashboard.manifests[each.value]
}
