
data aws_eks_cluster "cluster" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

locals {
  oidc_id = trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")
}

resource "aws_iam_role" "irsa" {
  name  = "kubeflow-secrets-manager-sa"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17"

    "Statement": [{
      "Action": "sts:AssumeRoleWithWebIdentity"
      "Effect": "Allow"
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_id}"
      }
      "Condition": {
        "StringEquals": {
          "${local.oidc_id}:sub": [
             "system:serviceaccount:kubeflow:kubeflow-secrets-manager-sa"
            ]
        }
      }
    }]
  })
}

resource aws_iam_role_policy_attachment "secret" {
  role = aws_iam_role.irsa.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource aws_iam_role_policy_attachment "ssm" {
  role = aws_iam_role.irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}




resource "kubectl_manifest" "irsa" {
    yaml_body = yamlencode({
  "apiVersion": "v1"
  "kind": "ServiceAccount"
  "metadata": {
      "name": aws_iam_role.irsa.name,
      "namespace": "kubeflow"
      "annotations": {
        "eks.amazonaws.com/role-arn": aws_iam_role.irsa.arn
      }
  }
  })
}

data "kustomization_build" "secret-manager" {
  path = "./distributions/aws/aws-secrets-manager/base"
}

resource "kustomization_resource" "secret-manager" {
  depends_on = [kubectl_manifest.irsa]
  for_each = data.kustomization_build.secret-manager.ids

  manifest = data.kustomization_build.secret-manager.manifests[each.value]
}
