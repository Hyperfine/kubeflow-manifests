
data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    "kubernetes.io/role/internal-elb": "1"
  }
}


data "aws_subnet" "all" {
  for_each = toset(data.aws_subnets.private.ids)
  id = each.value
}