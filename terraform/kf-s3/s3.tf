
resource "aws_s3_bucket" "source" {
  bucket = "kf-${var.cluster_name}-bucket"
}

resource "aws_iam_user" "s3_user" {
  name = "kf-${var.cluster_name}-s3"
}

resource "aws_iam_access_key" "s3_keys" {
  user = aws_iam_user.s3_user.name
}

resource "aws_iam_user_policy" "s3_user_policy" {
  name   = "${var.cluster_name}-kf-s3-secret"
  user   = aws_iam_user.s3_user.name
  policy = jsonencode(
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": [aws_s3_bucket.source.arn]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["${aws_s3_bucket.source.arn}/*"]
    }
  ]
}
  )
}

resource "aws_secretsmanager_secret" "s3-secret" {
  name = "${var.cluster_name}-kf-s3-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "s3-secret-version" {
  secret_id = aws_secretsmanager_secret.s3-secret.id
  secret_string=jsonencode({
      "accesskey":aws_iam_access_key.s3_keys.id,
      "secretkey":aws_iam_access_key.s3_keys.secret
  })
}
