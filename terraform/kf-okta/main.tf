terraform {
  required_providers {
    okta = {
      source = "okta/okta"
      version = "~> 3.20"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "< 4.0"
    }
  }
}

provider "okta" {
  org_name  = var.org_name
  base_url  = var.base_url
  api_token = var.api_token
}


resource "okta_app_oauth" "kf" {
  label = "kubeflow"
  type = "web"
  grant_types = ["authorization_code", "refresh_token"]
  redirect_uris = var.redirect_uris
  post_logout_redirect_uris = var.logout_uris
}

resource "okta_group" "kf-group" {
  name = "kf-group"
  description = "kubeflow users"
}

resource "okta_app_group_assignment" "kf-assign" {
  app_id = okta_app_oauth.kf.id
  group_id = okta_group.kf-group.id
}

resource "aws_secretsmanager_secret" "okta-secret" {
  name = "kf-okta-secret"
  recovery_window_in_days = 0
  kms_key_id = var.kms_key_id
}

resource "aws_secretsmanager_secret_version" "okta-version" {
  secret_id = aws_secretsmanager_secret.okta-secret.id
  secret_string=jsonencode({
      "okta_client_id":okta_app_oauth.kf.client_id,
      "okta_client_secret":okta_app_oauth.kf.client_secret,
      "okta_issuer_url": okta_app_oauth.kf.issuer_mode == "ORG_URL" ? "${var.org_name}.okta.com" : var.base_url
  })
}

