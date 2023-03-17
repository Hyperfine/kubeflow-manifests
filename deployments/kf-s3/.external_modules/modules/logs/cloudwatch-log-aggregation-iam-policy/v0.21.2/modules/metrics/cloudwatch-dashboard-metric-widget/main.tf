terraform {
  required_version = ">= 0.12"
}

locals {
  flavors = {
    positioned_widget = {
      type   = "metric"
      x      = var.x_axis
      y      = var.y_axis
      width  = var.width
      height = var.height
      properties = {
        metrics = var.metrics
        title   = var.title
        period  = var.period
        region  = data.aws_region.current.name
        stat    = var.stat
        view    = var.view
        stacked = var.stacked
      }
    }
    fluid_widget = {
      type   = "metric"
      width  = var.width
      height = var.height
      properties = {
        metrics = var.metrics
        title   = var.title
        period  = var.period
        region  = data.aws_region.current.name
        stat    = var.stat
        view    = var.view
        stacked = var.stacked
      }
    }
  }

  widget = local.flavors[var.x_axis < 0 || var.y_axis < 0 ? "fluid_widget" : "positioned_widget"]
}

data "aws_region" "current" {}
