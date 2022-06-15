
variable "kms_key_id" {
  type = string
}

variable "redirect_uris" {
  type = list(string)
}

variable "logout_uris" {
  type = list(string)
}

# PROVIDER CONFIGS

variable "org_name" {
  type = string
}

variable "base_url" {
  type = string
}

variable "api_token" {
  type = string
}
