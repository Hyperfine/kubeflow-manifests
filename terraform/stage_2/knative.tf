data "kustomization_build" "knative-serving" {
  path = "./common/knative/knative-serving/base"
}

data "kustomization_build" "knative-eventing" {
  path = "./common/knative/knative-eventing/base"
}

data "kustomization_build" "local-gateway" {
  path = "./common/istio-1-9/cluster-local-gateway/base"
}


resource "kustomization_resource" "knative-serving" {
  for_each = data.kustomization_build.knative-serving.ids

  manifest = data.kustomization_build.knative-serving.manifests[each.value]
}

resource "kustomization_resource" "knative-eventing" {
  for_each = data.kustomization_build.knative-eventing.ids

  manifest = data.kustomization_build.knative-eventing.manifests[each.value]
}

resource "kustomization_resource" "local-gateway" {
  for_each = data.kustomization_build.local-gateway.ids

  manifest = data.kustomization_build.local-gateway.manifests[each.value]
}
