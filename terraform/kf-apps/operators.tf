data "kustomization_build" "tf" {
  path = "./../../apps/tf-training/upstream/overlays/kubeflow"
}

data "kustomization_build" "pytorch" {
  path = "./../../apps/pytorch-job/upstream/overlays/kubeflow"
}

data "kustomization_build" "mpi" {
  path = "./../../apps/mpi-job/upstream/overlays/kubeflow"
}

data "kustomization_build" "mxnet" {
  path = "./../../apps/mxnet-job/upstream/overlays/kubeflow"
}

data "kustomization_build" "xgboost" {
  path = "./../../apps/xgboost-job/upstream/overlays/kubeflow"
}



resource "kustomization_resource" "tf" {
  for_each = data.kustomization_build.tf.ids

  manifest = data.kustomization_build.tf.manifests[each.value]
}

resource "kustomization_resource" "pytorch" {
  for_each = data.kustomization_build.pytorch.ids

  manifest = data.kustomization_build.pytorch.manifests[each.value]
}
resource "kustomization_resource" "mpi" {
  for_each = data.kustomization_build.mpi.ids

  manifest = data.kustomization_build.mpi.manifests[each.value]
}
resource "kustomization_resource" "mxnet" {
  for_each = data.kustomization_build.mxnet.ids

  manifest = data.kustomization_build.mxnet.manifests[each.value]
}
resource "kustomization_resource" "xgboost" {
  for_each = data.kustomization_build.xgboost.ids

  manifest = data.kustomization_build.xgboost.manifests[each.value]
}
