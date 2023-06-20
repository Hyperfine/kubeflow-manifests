terraform {
  required_version = ">= 1.0.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.71"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.13.1"
    }
  }
}


resource "aws_kms_key" "kms" {
  description             = "${var.eks_cluster_name}-kf-kms"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Allow access to kubeflow secrets",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            data.aws_caller_identity.current.arn,
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            aws_iam_user.s3_user.arn,
          ]
        },
        "Action" : [
          "kms:*"
        ],
        "Resource" : "*"
    }]
  })
}

resource "aws_kms_alias" "alias" {
  target_key_id = aws_kms_key.kms.key_id
  name          = "alias/${var.eks_cluster_name}-kf-kms"
}

resource "aws_iam_user" "s3_user" {
  #checkov:skip=CKV_AWS_273: https://github.com/awslabs/kubeflow-manifests/issues/44 minio proxy access
  name = "${var.eks_cluster_name}-${var.s3_bucket_name}-kf"
}

resource "aws_iam_access_key" "s3_keys" {
  user = aws_iam_user.s3_user.name
}

resource "aws_iam_policy" "s3_policy" {
  name = "${var.eks_cluster_name}-${var.s3_bucket_name}-secret"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ],
          "Resource" : [data.aws_s3_bucket.bucket.arn]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:GetBucketLocation",
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject"
          ],
          "Resource" : ["${data.aws_s3_bucket.bucket.arn}/*"]
        }
      ]
    }
  )
}

resource "aws_iam_group" "minio-group" {
  name = "${var.eks_cluster_name}-minio"
}

resource "aws_iam_group_membership" "minio-group-membership" {
  group = aws_iam_group.minio-group.name
  users = [aws_iam_user.s3_user.name]
  name  = "${var.eks_cluster_name}-minio-group-membership"
}

resource "aws_iam_group_policy_attachment" "s3-policy" {
  group      = aws_iam_group.minio-group.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_secretsmanager_secret" "s3-secret" {
  name                    = "${var.eks_cluster_name}-kf-s3-secret"
  recovery_window_in_days = 0
  kms_key_id              = aws_kms_key.kms.arn
}

resource "aws_secretsmanager_secret_version" "s3-secret-version" {
  secret_id = aws_secretsmanager_secret.s3-secret.id
  secret_string = jsonencode({
    "accesskey" : aws_iam_access_key.s3_keys.id,
    "secretkey" : aws_iam_access_key.s3_keys.secret
  })
}

resource "aws_secretsmanager_secret" "rds-secret" {
  name                    = "${var.eks_cluster_name}-kf-rds-secret"
  recovery_window_in_days = 0
  kms_key_id              = aws_kms_key.kms.arn
}

# add additional info to rds secret and encrypt for kubeflow
resource "aws_secretsmanager_secret_version" "rds-secret-version" {
  secret_id = aws_secretsmanager_secret.rds-secret.id
  secret_string = jsonencode({
    "database" : local.rds_secret["dbname"],
    "host" : var.rds_host,
    "password" : local.rds_secret["password"],
    "port" : local.rds_secret["port"],
    "username" : local.rds_secret["username"]
  })
}


data "aws_iam_policy_document" "kf-ssm" {
  version = "2012-10-17"

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = concat([aws_kms_key.kms.arn], var.additional_kms_key_arns)
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.rds-secret.arn, aws_secretsmanager_secret.s3-secret.arn]
  }
}
