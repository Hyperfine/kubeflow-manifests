data "kustomization_build" "cert" {
  path = "./common/cert-manager/cert-manager/base"
}
data "kustomization_build" "issuer" {
  path = "./common/cert-manager/kubeflow-issuer/base"
}
data "kubectl_file_documents" "kubeflow-issuer" {
  content = file("./common/cert-manager/kubeflow-issuer/base/cluster-issuer.yaml")
}

resource "kustomization_resource" "cert" {
  for_each = data.kustomization_build.cert.ids

  manifest = data.kustomization_build.cert.manifests[each.value]
}

resource "kubectl_manifest" "kubeflow-issuer" {
    for_each  = data.kubectl_file_documents.kubeflow-issuer.manifests
    yaml_body = each.value
}

/*
dont know why this fails
resource "kustomization_resource" "issuer" {
  for_each = data.kustomization_build.issuer.ids

  manifest = data.kustomization_build.issuer.manifests[each.value]
}*/