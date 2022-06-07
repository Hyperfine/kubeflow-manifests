
resource "kubectl_manifest" "dex_ingress" {
yaml_body =  <<YAML
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/scheme: internet-facing
    external-dns.alpha.kubernetes.io/hostname: "${var.subdomain}.${data.aws_route53_zone.top_level.name}"
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

