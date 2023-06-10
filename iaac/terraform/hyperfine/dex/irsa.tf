
resource "aws_iam_role" "oidc-irsa" {
  force_detach_policies = true
  name  = "${var.eks_cluster_name}-${var.oidc_sa_name}"
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
             "system:serviceaccount:${var.auth_namespace}:${var.oidc_sa_name}",
             "system:serviceaccount:istio-system:oidc-secrets-manager-sa"

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
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [for k, v in data.aws_secretsmanager_secret.oidc_secrets: v.arn]
  }
}

resource aws_iam_policy "oidc-ssm" {
  name = "${var.oidc_sa_name}-ssm-policy"
  policy = data.aws_iam_policy_document.ssm.json
}

resource aws_iam_role_policy_attachment "oidc-secret" {
  role = aws_iam_role.oidc-irsa.name
  policy_arn = aws_iam_policy.oidc-ssm.arn
}