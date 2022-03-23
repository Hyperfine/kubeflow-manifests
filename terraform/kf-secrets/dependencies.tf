data "aws_caller_identity" "current" {}

locals {
  oidc_id = trimprefix(var.oidc_url, "https://")
}
