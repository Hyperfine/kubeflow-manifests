provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
}


provider "kustomization" {
  kubeconfig_path = "~/.kube/config"
}

provider "aws" {
  region = var.region
}
