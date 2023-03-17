#!/bin/bash
#
# This script configures and runs the CloudWatch Logs Agent so it sends syslog to CloudWatch Logs.

set -e

readonly AWS_LOGS_CONF_PATH_AMAZON_LINUX="/etc/awslogs/awslogs.conf"
readonly AWS_LOGS_CONF_PATH_CENTOS_LINUX="/var/awslogs/etc/awslogs.conf"
readonly AWS_LOGS_CONF_PATH_OTHER_LINUX="/var/awslogs/etc/awslogs.conf"

readonly SYSLOG_PATH_AMAZON_LINUX="/var/log/messages"
readonly SYSLOG_PATH_CENTOS_LINUX="/var/log/messages"
readonly SYSLOG_PATH_OTHER_LINUX="/var/log/syslog"

readonly AUTH_LOG_PATH_UBUNTU="/var/log/auth.log"
readonly AUTH_LOG_PATH_CENTOS="/var/log/secure"

readonly DEFAULT_LOG_STREAM_NAME="{instance_id}"

function print_usage {
  echo
  echo "Usage: run-cloudwatch-logs-agent.sh [OPTIONS]"
  echo
  echo "This script configures and runs the CloudWatch Logs Agent so it sends syslog to CloudWatch Logs."
  echo
  echo "Options:"
  echo
  echo -e "  --log-group-name\tThe name to use for the log group. Required."
  echo -e "  --log-stream-name\tThe name to use for the log stream. Optional. Default: $DEFAULT_LOG_STREAM_NAME."
  echo -e "  --extra-log-file\tAn extra log file to include in log aggregation. Must be of the format name=path where name is a unique identifier and path is the path to the log file. May be specified more than once."
  echo
  echo "Example: run-cloudwatch-logs-agent.sh --log-group-name prod-ec2-syslog --extra-log-file nginx-errors=/var/log/nginx/nginx_error.log"
}

function configure_cloudwatch_logs_agent {
  local readonly log_group_name="$1"
  local readonly log_stream_name="$2"
  local readonly syslog_path="$3"
  local readonly config_file_path="$4"

  shift 4
  local readonly extra_log_files=($@)

  echo "Configuring CloudWatch Logs Agent with log group $log_group_name and log stream $log_stream_name"

  add_log_file_to_log_agent_config "syslog" "$syslog_path" "$log_group_name" "$log_stream_name" "$config_file_path"

  if os_is_ubuntu; then
    add_log_file_to_log_agent_config "auth" "$AUTH_LOG_PATH_UBUNTU" "$log_group_name" "$log_stream_name" "$config_file_path"
  elif os_is_centos || os_is_amazon_linux; then
    add_log_file_to_log_agent_config "secure" "$AUTH_LOG_PATH_CENTOS" "$log_group_name" "$log_stream_name" "$config_file_path"
  fi;

  local extra_log_file=""
  for extra_log_file in "${extra_log_files[@]}"; do
    # The extra_log_file param is of the format key=value. The code below gets the prefix before the "=" and the suffix
    # after the "=" as shown here: http://stackoverflow.com/a/16623897/483528
    local readonly log_file_name="${extra_log_file%%=*}"
    local readonly log_file_path="${extra_log_file##*=}"

    add_log_file_to_log_agent_config "$log_file_name" "$log_file_path" "$log_group_name" "$log_stream_name" "$config_file_path"
  done
}

function add_log_file_to_log_agent_config {
  local readonly log_file_name="$1"
  local readonly log_file_path="$2"
  local readonly log_group_name="$3"
  local readonly log_stream_name="$4"
  local readonly config_file_path="$5"

  echo "Adding log file $log_file_path to CloudWatch Logs Agent configuration at $config_file_path"

  tee --append "$config_file_path" > /dev/null << EOF

[${log_file_name}]
datetime_format = %b %d %H:%M:%S
file = ${log_file_path}
buffer_duration = 5000
initial_position = start_of_file
log_stream_name = ${log_stream_name}-${log_file_name}
log_group_name = ${log_group_name}
EOF
}

function get_ec2_instance_id {
  curl -s http://169.254.169.254/latest/meta-data/instance-id
}

function start_cloudwatch_logs_agent_amazon_linux {
  echo "Starting CloudWatch Logs Agent"

  service awslogs restart
  chkconfig awslogs on
}

function start_cloudwatch_logs_agent_amazon_linux_2 {
  echo "Starting CloudWatch Logs Agent"

  systemctl restart awslogsd.service
  systemctl enable awslogsd.service
}

function start_cloudwatch_logs_agent_other_linux {
  echo "Starting CloudWatch Logs Agent"

  service awslogs restart
}

# Returns true (0) if this is an Ubuntu server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_ubuntu {
  local readonly version="$1"
  grep -q "Ubuntu $version" /etc/*release
}

# Returns true (0) if this is an Amazon Linux server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_amazon_linux {
  local readonly version="$1"
  grep -q "Amazon Linux * $version" /etc/*release
}

# Returns true (0) if this is a CentOS server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_centos {
  local readonly version="$1"
  grep -q "CentOS Linux release $version" /etc/*release
}

function assert_not_empty {
  local readonly arg_name="$1"
  local readonly arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    echo "ERROR: The value for '$arg_name' cannot be empty"
    print_usage
    exit 1
  fi
}

function parse_args_and_configure_agent {
  local log_group_name=""
  local log_stream_name=""
  local extra_log_files=()

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --log-group-name)
        log_group_name="$2"
        shift
        ;;
      --log-stream-name)
        log_stream_name="$2"
        shift
        ;;
      --extra-log-file)
        extra_log_files+=("$2")
        shift
        ;;
      --help)
        print_usage
        exit
        ;;
      *)
        echo "ERROR: Unrecognized argument: $key"
        print_usage
        exit 1
        ;;
    esac

    shift
  done

  assert_not_empty "--log-group-name" "$log_group_name"
  
  if [[ -z "$log_stream_name" ]]; then
    log_stream_name="$(get_ec2_instance_id)"
  fi

  # See http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/QuickStartEC2Instance.html for the differences
  # between Amazon Linux and other Linux flavors
  if os_is_amazon_linux 2; then
    configure_cloudwatch_logs_agent "$log_group_name" "$log_stream_name" "$SYSLOG_PATH_AMAZON_LINUX" "$AWS_LOGS_CONF_PATH_AMAZON_LINUX" "${extra_log_files[@]}"
    start_cloudwatch_logs_agent_amazon_linux_2
  elif os_is_amazon_linux; then
    configure_cloudwatch_logs_agent "$log_group_name" "$log_stream_name" "$SYSLOG_PATH_AMAZON_LINUX" "$AWS_LOGS_CONF_PATH_AMAZON_LINUX" "${extra_log_files[@]}"
    start_cloudwatch_logs_agent_amazon_linux
  elif os_is_centos; then
    configure_cloudwatch_logs_agent "$log_group_name" "$log_stream_name" "$SYSLOG_PATH_CENTOS_LINUX" "$AWS_LOGS_CONF_PATH_CENTOS_LINUX" "${extra_log_files[@]}"
    start_cloudwatch_logs_agent_other_linux
  else
    configure_cloudwatch_logs_agent "$log_group_name" "$log_stream_name" "$SYSLOG_PATH_OTHER_LINUX" "$AWS_LOGS_CONF_PATH_OTHER_LINUX" "${extra_log_files[@]}"
    start_cloudwatch_logs_agent_other_linux
  fi
}

parse_args_and_configure_agent "$@"
