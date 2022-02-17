data "kubectl_file_documents" "ingress" {
  content =<<YAML
apiVersion: v1
data:
  CognitoAppClientId: ${var.cognito_client_id}
  CognitoUserPoolArn: ${var.pool_arn}
  CognitoUserPoolDomain: ${var.cognito_domain}
  certArn: ${var.cert_arn}
  loadBalancerScheme: internet-facing
kind: ConfigMap
metadata:
  name: istio-ingress-cognito-parameters
  namespace: istio-system
---
apiVersion: v1
data:
  loadBalancerScheme: internet-facing
kind: ConfigMap
metadata:
  labels:
    kustomize.component: istio-ingress
  name: istio-ingress-parameters
  namespace: istio-system
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/auth-idp-cognito: '{"UserPoolArn":"${var.pool_arn}","UserPoolClientId":"${var.cognito_client_id}", "UserPoolDomain":"${var.cognito_domain}"}'
    alb.ingress.kubernetes.io/auth-type: cognito
    alb.ingress.kubernetes.io/certificate-arn: ${var.cert_arn}
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/scheme: internet-facing
    kubernetes.io/ingress.class: alb
  labels:
    kustomize.component: istio-ingress
  name: istio-ingress
  namespace: istio-system
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: istio-ingressgateway
          servicePort: 80
        path: /*
YAML
}

data "kubectl_file_documents" "alb" {
  content = file("./.deploy/terraform/stage_1/alb.yaml")
}

data "kubectl_file_documents" "profiles" {
  content = file("./.deploy/terraform/stage_1/profiles.yaml")
}

data "kustomization_build" "envoy" {
  path = "./distributions/aws/aws-istio-envoy-filter/base"
}

data "aws_eks_cluster" "cluster" {
  name = "${var.region}-${var.cluster_name}"
}

data "aws_caller_identity" "current" {}

locals {
  oidc_id = trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")
}

resource "aws_iam_role" "ingress_role" {
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
             "system:serviceaccount:kubeflow:alb-ingress-controller",
             "system:serviceaccount:kubeflow:profiles-controller-service-account"
             ]
          }
         }
     }
     ]
 })
}

resource "aws_iam_role_policy" "ingress-policies" {
    role     = aws_iam_role.ingress_role.id
    policy   = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow"
          "Action" : [
          "elasticloadbalancing:ModifyListener",
          "wafv2:AssociateWebACL",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DescribeInstances",
          "wafv2:GetWebACLForResource",
          "elasticloadbalancing:RegisterTargets",
          "iam:ListServerCertificates",
          "wafv2:GetWebACL",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:SetWebAcl",
          "ec2:DescribeInternetGateways",
          "elasticloadbalancing:DescribeLoadBalancers",
          "waf-regional:GetWebACLForResource",
          "acm:GetCertificate",
          "shield:DescribeSubscription",
          "waf-regional:GetWebACL",
          "elasticloadbalancing:CreateRule",
          "ec2:DescribeAccountAttributes",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "waf:GetWebACL",
          "iam:GetServerCertificate",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "ec2:CreateTags",
          "elasticloadbalancing:CreateTargetGroup",
          "ec2:ModifyNetworkInterfaceAttribute",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "ec2:RevokeSecurityGroupIngress",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "shield:CreateProtection",
          "acm:DescribeCertificate",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:DescribeRules",
          "ec2:DescribeSubnets",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "waf-regional:AssociateWebACL",
          "tag:GetResources",
          "ec2:DescribeAddresses",
          "ec2:DeleteTags",
          "shield:DescribeProtection",
          "shield:DeleteProtection",
          "elasticloadbalancing:RemoveListenerCertificates",
          "tag:TagResources",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DescribeListeners",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateSecurityGroup",
          "acm:ListCertificates",
          "elasticloadbalancing:DescribeListenerCertificates",
          "ec2:ModifyInstanceAttribute",
          "elasticloadbalancing:DeleteRule",
          "cognito-idp:DescribeUserPoolClient",
          "ec2:DescribeInstanceStatus",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:CreateLoadBalancer",
          "waf-regional:DisassociateWebACL",
          "elasticloadbalancing:DescribeTags",
          "ec2:DescribeTags",
          "elasticloadbalancing:*",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteTargetGroup",
          "ec2:DescribeSecurityGroups",
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeVpcs",
          "ec2:DeleteSecurityGroup",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:DescribeTargetGroups",
          "shield:ListProtections",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:DeleteListener"
          ],
          "Resource": "*"
          }
      ]
    })
}

resource "kubectl_manifest" "profiles-controller-service-account" {
  yaml_body =<<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: profiles-controller-service-account
  namespace: kubeflow
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.ingress_role.arn}
YAML
}

resource "kubectl_manifest" "alb-ingress-controller" {
    yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: alb-ingress-controller
  namespace: kubeflow
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.ingress_role.arn}
YAML
}

resource "kubectl_manifest" "ingress" {
  depends_on = [kubectl_manifest.profiles-controller-service-account]
  for_each = data.kubectl_file_documents.ingress.manifests
  yaml_body = each.value
}

resource "kubectl_manifest" "alb" {
  depends_on = [kubectl_manifest.alb-ingress-controller]
  for_each = data.kubectl_file_documents.alb.manifests
  yaml_body = each.value
}
/*
resource "kubectl_manifest" "profiles" {
  for_each = data.kubectl_file_documents.profiles.manifests
  yaml_body = each.value
}
*/
resource "kustomization_resource" "envoy" {
  for_each = data.kustomization_build.envoy.ids

  manifest = data.kustomization_build.envoy.manifests[each.value]
}
