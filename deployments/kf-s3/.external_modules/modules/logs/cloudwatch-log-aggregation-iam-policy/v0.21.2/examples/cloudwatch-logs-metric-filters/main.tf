# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A CLOUDWATCH LOGS METRIC FILTER
# This is an example of how to create a CloudWatch Logs Metric Filter with an alarm and a new SNS topic
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CALL THE CLOUDWATCH LOGS FILTER MODULE
# ---------------------------------------------------------------------------------------------------------------------

module "cloudwatch_logs_metric_filter" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/cloudwatch-logs-metric-filters?ref=v1.0.8"
  source = "../../modules/logs/cloudwatch-logs-metric-filters"

  metric_map                 = var.metric_map
  cloudwatch_logs_group_name = var.cloudwatch_logs_group_name
  metric_namespace           = var.metric_namespace
  alarm_comparison_operator  = var.alarm_comparison_operator
  alarm_evaluation_periods   = var.alarm_evaluation_periods
  alarm_period               = var.alarm_period
  alarm_statistic            = var.alarm_statistic
  alarm_threshold            = var.alarm_threshold
  alarm_treat_missing_data   = var.alarm_treat_missing_data
  sns_topic_already_exists   = false
  sns_topic_name             = var.sns_topic_name
}
