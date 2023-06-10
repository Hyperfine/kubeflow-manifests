
resource "aws_iam_policy" "ssm-access" {
  name   = "${var.eks_cluster_name}-kf-secrets-manager-sa-policy"
  policy = data.aws_iam_policy_document.kf-ssm.json
}

module "irsa" {
  source                     = "git::git@github.com:hyperfine/terraform-aws-eks.git//modules/eks-irsa?ref=v0.48.1"
  kubernetes_namespace       = "kubeflow"
  kubernetes_service_account = "kf-secrets-manager-sa"
  irsa_iam_policies          = [aws_iam_policy.ssm-access.arn]
  eks_cluster_id             = var.eks_cluster_name

  create_kubernetes_namespace = false
  create_service_account_secret_token = true
}


resource "kubectl_manifest" "kf-secret-class" {
  depends_on = [module.irsa.*.]
  yaml_body  = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: aws-secrets
  namespace: "${module.irsa.namespace}"
spec:
  provider: aws
  secretObjects:
  - secretName: mysql-secret
    type: Opaque
    data:
    - objectName: "user"
      key: username
    - objectName: "pass"
      key: password
    - objectName: "host"
      key: host
    - objectName: "database"
      key: database
    - objectName: "port"
      key: port
  - secretName: mlpipeline-minio-artifact
    type: Opaque
    data:
    - objectName: "access"
      key: accesskey
    - objectName: "secret"
      key: secretkey
  parameters:
    objects: |
      - objectName: "${aws_secretsmanager_secret.rds-secret.name}"
        objectType: "secretsmanager"
        objectAlias: "rds-secret"
        objectVersionLabel: "AWSCURRENT"
        jmesPath:
            - path: "username"
              objectAlias: "user"
            - path: "password"
              objectAlias: "pass"
            - path: "host"
              objectAlias: "host"
            - path: "database"
              objectAlias: "database"
            - path: "port"
              objectAlias: "port"
      - objectName: "${aws_secretsmanager_secret.s3-secret.name}"
        objectType: "secretsmanager"
        objectAlias: "s3-secret"
        objectVersionLabel: "AWSCURRENT"
        jmesPath:
            - path: "accesskey"
              objectAlias: "access"
            - path: "secretkey"
              objectAlias: "secret"
YAML
}


resource "kubectl_manifest" "kf-secret-pod" {
  depends_on = [kubectl_manifest.kf-secret-class]
  yaml_body  = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kf-secrets-deployment
  namespace: "${module.irsa.namespace}"
  labels:
    app: kf-secrets
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kf-secrets
  template:
    metadata:
      labels:
        app: kf-secrets
    spec:
      containers:
      - image: k8s.gcr.io/e2e-test-images/busybox:1.29
        command:
        - "/bin/sleep"
        - "10000"
        name: secrets
        volumeMounts:
        - mountPath: "/mnt/rds-store"
          name: "${aws_secretsmanager_secret.rds-secret.name}"
          readOnly: true
        - mountPath: "/mnt/aws-store"
          name: "${aws_secretsmanager_secret.s3-secret.name}"
          readOnly: true
      serviceAccountName: "${module.irsa.service_account}"
      volumes:
      - csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: aws-secrets
        name: "${aws_secretsmanager_secret.rds-secret.name}"
      - csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: aws-secrets
        name: "${aws_secretsmanager_secret.s3-secret.name}"
YAML
}
