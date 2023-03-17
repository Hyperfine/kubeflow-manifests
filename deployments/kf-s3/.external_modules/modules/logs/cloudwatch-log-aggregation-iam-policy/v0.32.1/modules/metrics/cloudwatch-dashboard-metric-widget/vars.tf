# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "metrics" {
  description = "A list of metrics to include."
  type        = list(any)

  # A list of lists containing metric information in the format:
  # [Namespace, MetricName, Dimension1Name, Dimension1Value, Dimension2Name, Dimension2Value...]
  # See https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html#CloudWatch-Dashboard-Properties-Metrics-Array-Format for more information
  #
  # Example:
  # [
  #   [ "AWS/EC2", "CPUUtilization", "InstanceId", "i-abc" ],
  #   [ "AWS/EC2", "CPUUtilization", "InstanceId", "i-xyz" ],
  # ]
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

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

variable "title" {
  description = "The title to be displayed for the graph or number."
  type        = string
  default     = ""
}

variable "period" {
  description = "The default period, in seconds, for all metrics in this widget."
  type        = number
  default     = 300
}

variable "stat" {
  description = "The default statistic to be displayed for each metric in the array. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#Statistic for valid values."
  type        = string
  default     = "SampleCount"
}

variable "view" {
  description = "Specify timeSeries to display this metric as a graph, or singleValue to display it as a number."
  type        = string
  default     = "timeSeries"
}

variable "stacked" {
  description = "Display the graph as a stacked line."
  type        = bool
  default     = false
}
