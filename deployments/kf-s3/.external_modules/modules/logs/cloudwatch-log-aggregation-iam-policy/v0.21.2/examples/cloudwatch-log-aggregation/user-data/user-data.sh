#!/bin/bash
#
# A script run in User Data that:
#
# 1. Starts the CloudWatch Logs Agent using the run-cloudwatch-logs-agent.sh script
# 2. Logs some test data to syslog, which the CloudWatch Logs Agent will send to CloudWatch Logs

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

function start_cloudwatch_logs_agent {
  local readonly log_group_name="$1"

  echo "Starting CloudWatch Logs Agent"
  /etc/user-data/cloudwatch-log-aggregation/run-cloudwatch-logs-agent.sh \
    --log-group-name "$log_group_name" \
    --extra-log-file kern=/var/log/kern.log
}

# An example of how to log to syslog. Everything in syslog will be available in CloudWatch Logs.
function log_to_syslog {
  local readonly text_to_log="$1"

  echo "Logging $text_to_log to syslog"
  echo "$text_to_log" | logger
}

function setup {
  local readonly text_to_log="$1"
  local readonly log_group_name="$2"

  start_cloudwatch_logs_agent "$log_group_name"
  log_to_syslog "$text_to_log"
}

# This variables should be filled in by Terraform interpolation
setup "${text_to_log}" \
      "${log_group_name}"
