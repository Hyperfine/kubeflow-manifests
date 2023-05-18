
resource "aws_iam_role" "irsa" {
  force_detach_policies = true
  name  = "${local.sa_name}"
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
             "system:serviceaccount:${local.key}:${local.sa_name}"
            ]
        }
      }
    }]
  })
}


data aws_iam_policy_document "ssm" {
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
  name = "kf-${local.key}-sa-ssm-policy"
  policy = data.aws_iam_policy_document.ssm.json
}

resource aws_iam_role_policy_attachment "secret" {
  role = aws_iam_role.irsa.name
  policy_arn = aws_iam_policy.ssm.arn
}

resource "kubectl_manifest" "irsa" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${local.sa_name}
  namespace: ${local.key}
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.irsa.arn}
YAML
}
resource "kubectl_manifest" "role" {
  yaml_body = <<YAML
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${local.key}-access
  namespace: ${local.key}
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["extensions"]
  resources: ["*"]
  verbs: ["*"]
YAML
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
    name:  ${local.sa_name}
    namespace: ${local.key}
YAML
}


resource "kubectl_manifest" "group-role-binding" {
  depends_on = [time_sleep.wait_for_namespace]
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