data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [for s in data.aws_eks_cluster.eks.vpc_config : s.vpc_id]
  }
  tags = {
    "kubernetes.io/role/internal-elb": "1"
  }
}


data "aws_subnet" "all" {
  for_each = toset(data.aws_subnets.private.ids)
  id = each.value
}