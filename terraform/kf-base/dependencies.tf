data aws_eks_cluster "eks" {
  name = var.cluster_name
}

data aws_eks_cluster_auth "eks" {
  name = data.aws_eks_cluster.eks.name
}
