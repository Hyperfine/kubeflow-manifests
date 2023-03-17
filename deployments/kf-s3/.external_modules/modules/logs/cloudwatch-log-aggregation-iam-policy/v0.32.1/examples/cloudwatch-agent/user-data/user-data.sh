#!/bin/bash
#
# A script run in User Data that:
#
# 1. Starts the CloudWatch Unified Agent using the restart-cloudwatch-agent.sh script
# 2. Logs some test data to syslog, which the CloudWatch Unified Agent will send to CloudWatch Logs

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# An example of how to log to syslog. Everything in syslog will be available in CloudWatch Logs.
function log_to_syslog {
  local -r text_to_log="$1"
  echo "Logging $text_to_log to syslog"
  echo "$text_to_log" | logger
}

function start_cloudwatch_agent {
  local -r log_group_name="$1"

  echo "Configuring CloudWatch Agent"
  /etc/user-data/cloudwatch-agent/configure-cloudwatch-agent.sh \
    --syslog --authlog --log-file /var/log/kern.log \
    --log-group-name "$log_group_name" --log-stream-name '{instance_id}-syslog' \
    %{ if disable_cpu_metrics }--disable-cpu-metrics%{ endif } %{ if disable_mem_metrics }--disable-mem-metrics%{ endif } %{ if disable_disk_metrics }--disable-disk-metrics%{ endif }

  echo "Starting CloudWatch Agent"
  /etc/user-data/cloudwatch-agent/restart-cloudwatch-agent.sh
}

function setup {
  local -r text_to_log="$1"
  local -r log_group_name="$2"

  # If the PATH does not contain /usr/local/bin, add it in as certain scripts are installed there in the AMI. This
  # should only be necessary on Amazon Linux version 1.
  if [[ $PATH != *"/usr/local/bin"* ]]; then
    export PATH="/usr/local/bin:$PATH"
  fi

  start_cloudwatch_agent "$log_group_name"
  log_to_syslog "$text_to_log"
}

# This variables should be filled in by Terraform interpolation
setup "${text_to_log}" "${log_group_name}"
