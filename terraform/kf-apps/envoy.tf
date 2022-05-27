
data "kustomization_build" "envoy" {
  path = "./../../distributions/aws/aws-istio-envoy-filter/base"
}
resource "kustomization_resource" "envoy" {
  for_each = data.kustomization_build.envoy.ids

  manifest = data.kustomization_build.envoy.manifests[each.value]
}
