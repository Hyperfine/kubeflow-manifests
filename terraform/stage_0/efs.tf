data "kustomization_build" "efs" {
  path = "./apps/efs-csi-driver/overlays/stable"
}

resource "kustomization_resource" "efs" {
  for_each = data.kustomization_build.efs.ids

  manifest = data.kustomization_build.efs.manifests[each.value]
}

resource "aws_iam_role" "efs" {
  name = "kf-admin-${var.region}-${var.cluster_name}-role"
  assume_role_policy = jsonencode({
     "Version": "2012-10-17",
     "Statement": [
     {
         "Effect": "Allow",
         "Principal": {
         "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_id}"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
         "StringEquals": {
             "${local.oidc_id}:aud": "sts.amazonaws.com",
             "${local.oidc_id}:sub": [
             "system:serviceaccount:kubeflow:efs-csi-controller-sa",
             ]
          }
         }
     }
     ]
 })
}


data "aws_eks_cluster" "cluster" {
  name = "${var.region}-${var.cluster_name}"
}

data "aws_caller_identity" "current" {}

locals {
  oidc_id = trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")
}

resource "aws_iam_role_policy" "ingress-policies" {
    role     = aws_iam_role.efs.id
    policy   = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:DescribeFileSystems"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:CreateAccessPoint"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/efs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "elasticfilesystem:DeleteAccessPoint",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
})
}

resource aws_iam_role_policy "cross" {
  role = aws_iam_role.efs.id
  policy = jsonencode(
          {
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::123456789012:role/EFSCrossAccountAccessRole"
  }
}
  )
}

data aws_efs_file_system "efs-fs" {
  tags = {
    Name = var.efs_name
  }
}
