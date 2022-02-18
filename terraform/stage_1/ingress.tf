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
  yaml_body = <<YAML
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

resource "kubectl_manifest" "alb" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    app: aws-alb-ingress-controller
    kustomize.component: aws-alb-ingress-controller
  name: alb-ingress-controller
rules:
- apiGroups:
  - ""
  - extensions
  resources:
  - configmaps
  - endpoints
  - events
  - ingresses
  - ingresses/status
  - services
  verbs:
  - create
  - get
  - list
  - update
  - watch
  - patch
- apiGroups:
  - ""
  - extensions
  resources:
  - nodes
  - pods
  - secrets
  - services
  - namespaces
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app: aws-alb-ingress-controller
    kustomize.component: aws-alb-ingress-controller
  name: alb-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: alb-ingress-controller
subjects:
- kind: ServiceAccount
  name: alb-ingress-controller
---
apiVersion: v1
data:
  clusterName: ${data.aws_eks_cluster.cluster.name}
  iamRole: ${aws_iam_role.ingress_role.arn}
kind: ConfigMap
metadata:
  labels:
    app: aws-alb-ingress-controller
    kustomize.component: aws-alb-ingress-controller
  name: aws-alb-ingress-controller-config
  namespace: kubeflow
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: aws-alb-ingress-controller
    kustomize.component: aws-alb-ingress-controller
  name: alb-ingress-controller
  namespace: kubeflow
spec:
  selector:
    matchLabels:
      app: aws-alb-ingress-controller
      app.kubernetes.io/name: alb-ingress-controller
      kustomize.component: aws-alb-ingress-controller
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "false"
      labels:
        app: aws-alb-ingress-controller
        app.kubernetes.io/name: alb-ingress-controller
        kustomize.component: aws-alb-ingress-controller
    spec:
      containers:
      - args:
        - --ingress-class=alb
        - --cluster-name=$(CLUSTER_NAME)
        env:
        - name: CLUSTER_NAME
          valueFrom:
            configMapKeyRef:
              key: clusterName
              name: aws-alb-ingress-controller-config
        - name: IAM_ROLE
          valueFom:
            configMapKeyRef:
              key: iamRole
              name: aws-alb-ingress-controller-config
        image: docker.io/amazon/aws-alb-ingress-controller:v1.1.5
        imagePullPolicy: Always
        name: alb-ingress-controller
      serviceAccountName: alb-ingress-controller
YAML
}

resource "kubectl_manifest" "profiles" {
  yaml_body = <<YAML
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.4.0
  labels:
    kustomize.component: profiles
  name: profiles.kubeflow.org
spec:
  conversion:
    strategy: None
  group: kubeflow.org
  names:
    kind: Profile
    listKind: ProfileList
    plural: profiles
    singular: profile
  scope: Cluster
  versions:
  - name: v1
    schema:
      openAPIV3Schema:
        description: Profile is the Schema for the profiles API
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: ProfileSpec defines the desired state of Profile
            properties:
              owner:
                description: The profile owner
                properties:
                  apiGroup:
                    description: APIGroup holds the API group of the referenced subject. Defaults to "" for ServiceAccount subjects. Defaults to "rbac.authorization.k8s.io" for User and Group subjects.
                    type: string
                  kind:
                    description: Kind of object being referenced. Values defined by this API group are "User", "Group", and "ServiceAccount". If the Authorizer does not recognized the kind value, the Authorizer should report an error.
                    type: string
                  name:
                    description: Name of the object being referenced.
                    type: string
                  namespace:
                    description: Namespace of the referenced object.  If the object kind is non-namespace, such as "User" or "Group", and this value is not empty the Authorizer should report an error.
                    type: string
                required:
                - kind
                - name
                type: object
              plugins:
                items:
                  description: Plugin is for customize actions on different platform.
                  properties:
                    apiVersion:
                      description: 'APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
                      type: string
                    kind:
                      description: 'Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
                      type: string
                    spec:
                      type: object
                      x-kubernetes-preserve-unknown-fields: true
                  type: object
                type: array
              resourceQuotaSpec:
                description: Resourcequota that will be applied to target namespace
                properties:
                  hard:
                    additionalProperties:
                      anyOf:
                      - type: integer
                      - type: string
                      pattern: ^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$
                      x-kubernetes-int-or-string: true
                    description: 'hard is the set of desired hard limits for each named resource. More info: https://kubernetes.io/docs/concepts/policy/resource-quotas/'
                    type: object
                  scopeSelector:
                    description: scopeSelector is also a collection of filters like scopes that must match each object tracked by a quota but expressed using ScopeSelectorOperator in combination with possible values. For a resource to match, both scopes AND scopeSelector (if specified in spec), must be matched.
                    properties:
                      matchExpressions:
                        description: A list of scope selector requirements by scope of the resources.
                        items:
                          description: A scoped-resource selector requirement is a selector that contains values, a scope name, and an operator that relates the scope name and values.
                          properties:
                            operator:
                              description: Represents a scope's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist.
                              type: string
                            scopeName:
                              description: The name of the scope that the selector applies to.
                              type: string
                            values:
                              description: An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.
                              items:
                                type: string
                              type: array
                          required:
                          - operator
                          - scopeName
                          type: object
                        type: array
                    type: object
                  scopes:
                    description: A collection of filters that must match each object tracked by a quota. If not specified, the quota matches all objects.
                    items:
                      description: A ResourceQuotaScope defines a filter that must match each object tracked by a quota
                      type: string
                    type: array
                type: object
            type: object
          status:
            description: ProfileStatus defines the observed state of Profile
            properties:
              conditions:
                items:
                  properties:
                    message:
                      type: string
                    status:
                      type: string
                    type:
                      type: string
                  type: object
                type: array
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
  - name: v1beta1
    schema:
      openAPIV3Schema:
        description: Profile is the Schema for the profiles API
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: ProfileSpec defines the desired state of Profile
            properties:
              owner:
                description: The profile owner
                properties:
                  apiGroup:
                    description: APIGroup holds the API group of the referenced subject. Defaults to "" for ServiceAccount subjects. Defaults to "rbac.authorization.k8s.io" for User and Group subjects.
                    type: string
                  kind:
                    description: Kind of object being referenced. Values defined by this API group are "User", "Group", and "ServiceAccount". If the Authorizer does not recognized the kind value, the Authorizer should report an error.
                    type: string
                  name:
                    description: Name of the object being referenced.
                    type: string
                  namespace:
                    description: Namespace of the referenced object.  If the object kind is non-namespace, such as "User" or "Group", and this value is not empty the Authorizer should report an error.
                    type: string
                required:
                - kind
                - name
                type: object
              plugins:
                items:
                  description: Plugin is for customize actions on different platform.
                  properties:
                    apiVersion:
                      description: 'APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
                      type: string
                    kind:
                      description: 'Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
                      type: string
                    spec:
                      type: object
                      x-kubernetes-preserve-unknown-fields: true
                  type: object
                type: array
              resourceQuotaSpec:
                description: Resourcequota that will be applied to target namespace
                properties:
                  hard:
                    additionalProperties:
                      anyOf:
                      - type: integer
                      - type: string
                      pattern: ^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$
                      x-kubernetes-int-or-string: true
                    description: 'hard is the set of desired hard limits for each named resource. More info: https://kubernetes.io/docs/concepts/policy/resource-quotas/'
                    type: object
                  scopeSelector:
                    description: scopeSelector is also a collection of filters like scopes that must match each object tracked by a quota but expressed using ScopeSelectorOperator in combination with possible values. For a resource to match, both scopes AND scopeSelector (if specified in spec), must be matched.
                    properties:
                      matchExpressions:
                        description: A list of scope selector requirements by scope of the resources.
                        items:
                          description: A scoped-resource selector requirement is a selector that contains values, a scope name, and an operator that relates the scope name and values.
                          properties:
                            operator:
                              description: Represents a scope's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist.
                              type: string
                            scopeName:
                              description: The name of the scope that the selector applies to.
                              type: string
                            values:
                              description: An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.
                              items:
                                type: string
                              type: array
                          required:
                          - operator
                          - scopeName
                          type: object
                        type: array
                    type: object
                  scopes:
                    description: A collection of filters that must match each object tracked by a quota. If not specified, the quota matches all objects.
                    items:
                      description: A ResourceQuotaScope defines a filter that must match each object tracked by a quota
                      type: string
                    type: array
                type: object
            type: object
          status:
            description: ProfileStatus defines the observed state of Profile
            properties:
              conditions:
                items:
                  properties:
                    message:
                      type: string
                    status:
                      type: string
                    type:
                      type: string
                  type: object
                type: array
            type: object
        type: object
    served: true
    storage: false
    subresources:
      status: {}
status:
  acceptedNames:
    kind: ""
    plural: ""
  conditions: []
  storedVersions: []
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    kustomize.component: profiles
  name: profiles-leader-election-role
  namespace: kubeflow
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - ""
  resources:
  - configmaps/status
  verbs:
  - get
  - update
  - patch
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    kustomize.component: profiles
  name: profiles-leader-election-rolebinding
  namespace: kubeflow
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: profiles-leader-election-role
subjects:
- kind: ServiceAccount
  name: controller-service-account
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    kustomize.component: profiles
  name: profiles-cluster-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: controller-service-account
---
apiVersion: v1
data:
  ADMIN: ""
  USERID_HEADER: kubeflow-userid
  USERID_PREFIX: ""
  WORKLOAD_IDENTITY: ""
kind: ConfigMap
metadata:
  labels:
    kustomize.component: profiles
  name: profiles-config-46c7tgh6fd
  namespace: kubeflow
---
apiVersion: v1
kind: Service
metadata:
  labels:
    kustomize.component: profiles
  name: profiles-kfam
  namespace: kubeflow
spec:
  ports:
  - port: 8081
  selector:
    kustomize.component: profiles
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    kustomize.component: profiles
  name: profiles-deployment
  namespace: kubeflow
spec:
  replicas: 1
  selector:
    matchLabels:
      kustomize.component: profiles
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "false"
      labels:
        kustomize.component: profiles
    spec:
      containers:
      - command:
        - /access-management
        - -cluster-admin
        - $(ADMIN)
        - -userid-header
        - $(USERID_HEADER)
        - -userid-prefix
        - $(USERID_PREFIX)
        envFrom:
        - configMapRef:
            name: profiles-config-46c7tgh6fd
        image: public.ecr.aws/j1r0q0g6/notebooks/access-management:v1.3.1-rc.0
        imagePullPolicy: Always
        livenessProbe:
          httpGet:
            path: /metrics
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 30
        name: kfam
        ports:
        - containerPort: 8081
          name: kfam-http
          protocol: TCP
      - command:
        - /manager
        - -userid-header
        - $(USERID_HEADER)
        - -userid-prefix
        - $(USERID_PREFIX)
        - -workload-identity
        - $(WORKLOAD_IDENTITY)
        envFrom:
        - configMapRef:
            name: profiles-config-46c7tgh6fd
        image: public.ecr.aws/j1r0q0g6/notebooks/profile-controller:v1.3.1-rc.0
        imagePullPolicy: Always
        livenessProbe:
          httpGet:
            path: /metrics
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
        name: manager
        ports:
        - containerPort: 8080
          name: manager-http
          protocol: TCP
      serviceAccountName: controller-service-account
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  labels:
    kustomize.component: profiles
  name: profiles-kfam
  namespace: kubeflow
spec:
  gateways:
  - kubeflow-gateway
  hosts:
  - '*'
  http:
  - headers:
      request:
        add:
          x-forwarded-prefix: /kfam
    match:
    - uri:
        prefix: /kfam/
    rewrite:
      uri: /kfam/
    route:
    - destination:
        host: profiles-kfam.kubeflow.svc.cluster.local
        port:
          number: 8081
YAML
}

resource "kustomization_resource" "envoy" {
  for_each = data.kustomization_build.envoy.ids

  manifest = data.kustomization_build.envoy.manifests[each.value]
}
