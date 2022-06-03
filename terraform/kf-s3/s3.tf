module "bucket" {
  source = "git::git@github.com:Hyperfine/terraform-aws-service-catalog//modules/data-stores/s3-bucket?ref=v0.67.2"


  primary_bucket = "kf-${var.eks_cluster_name}"
  access_logging_bucket = "kf-${var.eks_cluster_name}-access-logs"
  enable_versioning = false
  bucket_kms_key_arn = aws_kms_key.kms.arn
}

resource "aws_kms_key" "kms" {
  description             = "s3-kf-${var.eks_cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation = true
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid" : "Allow Access to S3",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : [
          aws_iam_group.minio-group.arn,
          # "${aws_iam_role.s3_role.arn}",
          "${data.aws_caller_identity.current.arn}"
        ]
      },
      "Action" : [
        "kms:*"
      ],
      "Resource" : "*"
    }]
  })
}

resource aws_kms_alias "alias" {
  target_key_id = aws_kms_key.kms.key_id
  name = "alias/s3-kf-${var.eks_cluster_name}-kms"
}

resource "aws_iam_user" "s3_user" {
  name = "kf-${var.eks_cluster_name}-s3"
}

resource "aws_iam_access_key" "s3_keys" {
  user = aws_iam_user.s3_user.name
}

resource "aws_iam_policy" "s3_policy" {
  depends_on = [module.bucket]
  name   = "${var.eks_cluster_name}-kf-s3-secret"
  policy = jsonencode(
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [module.bucket.primary_bucket_arn]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["${module.bucket.primary_bucket_arn}/*"]
    }
  ]
}
  )
}

resource "aws_iam_group" "minio-group" {
  name = "minio-group"
}

resource "aws_iam_group_membership" "minio-group-membership" {
  group = aws_iam_group.minio-group.arn
  users = [aws_iam_user.s3_user.arn]
  name = "minio-group-membership"
}

resource "aws_iam_policy_attachment" "s3-policy" {
  name = "kf-s3-policy-attachment"
  policy_arn = aws_iam_policy.s3_policy.arn
  groups = [aws_iam_group.minio_group.arn]
}

/*
# https://github.com/kubeflow/pipelines/issues/3398 minio support for roles
data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      identifiers = [aws_iam_user.s3_user.arn]
      type        = "AWS"
    }
  }
}

resource "aws_iam_role" "s3_role" {
  name = "kf-${var.eks_cluster_name}-s3-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.s3_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}
*/

resource "aws_secretsmanager_secret" "s3-secret" {
  name = "kf-s3-secret"
  recovery_window_in_days = 0
  kms_key_id = aws_kms_key.kms.arn
}

# https://github.com/kubeflow/manifests/issues/2061 minio proxy access
resource "aws_secretsmanager_secret_version" "s3-secret-version" {
  secret_id = aws_secretsmanager_secret.s3-secret.id
  secret_string=jsonencode({
      "accesskey":aws_iam_access_key.s3_keys.id,
      "secretkey":aws_iam_access_key.s3_keys.secret
  })
}
