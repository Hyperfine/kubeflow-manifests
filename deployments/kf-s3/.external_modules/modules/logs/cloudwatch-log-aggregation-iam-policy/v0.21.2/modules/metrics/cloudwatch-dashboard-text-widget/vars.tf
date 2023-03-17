# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "markdown" {
  description = "The text to be displayed by the widget."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "title" {
  description = "The title heading for the widget."
  type        = string
  default     = ""
}

variable "x_axis" {
  description = "The horizontal position of the widget on the 24 column dashboard grid."
  type        = number
  default     = -1
}

variable "y_axis" {
  description = "The vertical position of the widget on the 24 column dashboard grid."
  type        = number
  default     = -1
}

variable "width" {
  description = "The width of the widget in grid units in a 24 column grid."
  type        = number
  default     = 6
}

variable "height" {
  description = "The height of the widget in grid units in a 24 column grid."
  type        = number
  default     = 6
}
