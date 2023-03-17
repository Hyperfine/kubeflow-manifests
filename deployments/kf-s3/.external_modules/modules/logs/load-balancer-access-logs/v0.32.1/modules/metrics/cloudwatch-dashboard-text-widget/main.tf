terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 4.0"
    }
  }
}

locals {
  flavors = {
    positioned_widget = {
      type   = "text"
      x      = var.x_axis
      y      = var.y_axis
      width  = var.width
      height = var.height
      properties = {
        title    = var.title
        markdown = var.markdown
      }
    }
    fluid_widget = {
      type   = "text"
      width  = var.width
      height = var.height
      properties = {
        title    = var.title
        markdown = var.markdown
      }
    }
  }

  widget = local.flavors[var.x_axis == -1 || var.y_axis == -1 ? "fluid_widget" : "positioned_widget"]
}
