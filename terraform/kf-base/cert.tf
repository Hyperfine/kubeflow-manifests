data "kustomization_build" "cert" {
  path = "./../../common/cert-manager/cert-manager/base"
}

resource "kustomization_resource" "cert" {
  for_each = data.kustomization_build.cert.ids

  manifest = data.kustomization_build.cert.manifests[each.value]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [kustomization_resource.cert]

  create_duration = "30s"
}

resource "kubectl_manifest" "kubeflow-issuer" {
  depends_on = [time_sleep.wait_30_seconds]

    yaml_body = <<YAML
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  labels:
    app.kubernetes.io/component: cert-manager
    app.kubernetes.io/name: cert-manager
    kustomize.component: cert-manager
  name: kubeflow-self-signing-issuer
  namespace: cert-manager
spec:
  selfSigned: {}
YAML
}
