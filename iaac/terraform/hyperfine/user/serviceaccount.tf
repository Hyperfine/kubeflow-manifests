data "aws_iam_policy_document" "ssm" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = ["kms:Decrypt", "kms:DescribeKey"]
    resources = var.kms_key_ids
  }

  statement {
    effect    = "Allow"
    actions   = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [for k, v in data.aws_secretsmanager_secret.secrets: v.arn]
  }
}

resource aws_iam_policy "ssm" {
  name = "${var.eks_cluster_name}-${local.key}-sa-ssm-policy"
  policy = data.aws_iam_policy_document.ssm.json
}


module "irsa" {
  source                     = "git::git@github.com:hyperfine/terraform-aws-eks.git//modules/eks-irsa?ref=bugfix/stateless-irsa"
  kubernetes_namespace       = local.key
  kubernetes_service_account = local.sa_name
  irsa_iam_policies          = [aws_iam_policy.ssm.arn]
  eks_cluster_id             = var.eks_cluster_name

  create_kubernetes_namespace         = false
  create_service_account_secret_token = true
}

locals {
  module_sa = reverse(split("/", module.irsa.service_account))[0] # implicit dependency
}

resource "kubectl_manifest" "binding" {
  yaml_body = <<YAML
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${local.key}-role-binding
  namespace: ${local.key}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${local.key}-access
subjects:
  - kind: ServiceAccount
    name:  ${local.module_sa}
    namespace: ${local.key}
YAML
}


resource "kubectl_manifest" "group-role-binding" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${local.key}-access-dashboard-cluster-role-binding
  namespace: ${local.key}
subjects:
- kind: Group
  name: kubernetes-dashboard
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ${local.key}-access
  apiGroup: rbac.authorization.k8s.io
YAML
}
