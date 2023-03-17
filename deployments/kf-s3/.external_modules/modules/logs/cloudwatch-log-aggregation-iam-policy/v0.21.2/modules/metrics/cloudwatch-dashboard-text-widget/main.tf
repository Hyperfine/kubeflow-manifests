terraform {
  required_version = ">= 0.12"
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
