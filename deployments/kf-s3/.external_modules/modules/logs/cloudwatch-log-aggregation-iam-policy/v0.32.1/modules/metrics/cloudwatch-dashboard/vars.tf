# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "dashboards" {
  description = "A map of names to widgets to include in the dashboard. Each entry of the map corresponds to a different cloudwatch dashboard."
  # The structure of each widget depends on what metrics you want to include in the dashboard. Given the complexity of
  # the widgets structure, we recommend using the `cloudwatch-dashboard-metric-widget` and
  # `cloudwatch-dashboard-text-widget` modules to construct each entry. See `examples/cloudwatch-dashboard` for an
  # example of how to use the widget modules in combination with this module.

  # We have to use the `any` type here because the type of the widgets will be dynamic. Both map and list type requires
  # each element to have the same type, but since each object in the widgets list has an arbitrary nesting of different
  # complex data types, they will not be the same type. Hence, we use `any` to skip the type system.
  type = any
}
