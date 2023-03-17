#!/bin/bash
#
# This script configures the CloudWatch Agent to customize its parameters. The following configuration parameters can be
# customized with this script:
# - What OS user to run the agent as
# - What log files to ship to CloudWatch Logs
# - Which CloudWatch Log Group and Log Stream to use for shipping the logs
#
# If there are further customization needs, we recommend directly generating a new config using the CloudWatch Agent
# Configuration Wizard
# (https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-cloudwatch-agent-configuration-file-wizard.html).

set -e

readonly BASH_COMMONS_DIR='/opt/gruntwork/bash-commons'
source "$BASH_COMMONS_DIR/assert.sh"
source "$BASH_COMMONS_DIR/os.sh"
source "$BASH_COMMONS_DIR/log.sh"

readonly AGENT_CONFIG_JSON_PATH='/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json'
readonly CONFIG_FILE_COLLECT_LIST_ADDR='.logs.logs_collected.files.collect_list'
readonly CONFIG_FILE_OS_USER_ADDR='.agent.run_as_user'
readonly DEFAULT_LOG_STREAM_NAME='{instance_id}'
readonly DEFAULT_OS_USER='root'

readonly SYSLOG_PATH_AMAZON_LINUX='/var/log/messages'
readonly SYSLOG_PATH_OTHER_LINUX='/var/log/syslog'

readonly AUTH_LOG_PATH_AMAZON_LINUX='/var/log/secure'
readonly AUTH_LOG_PATH_OTHER_LINUX='/var/log/auth.log'

function print_usage {
  >&2 echo
  >&2 echo "Usage: configure-cloudwatch-agent.sh [OPTIONS]"
  >&2 echo
  >&2 echo "This script configures CloudWatch Unified Agent so it sends metrics to CloudWatch and log files on the system to CloudWatch Logs. Call multiple times to configure multiple metrics or log files."
  >&2 echo
  >&2 echo "Options:"
  >&2 echo
  >&2 echo -e "  --log-file\tLog file to include in log aggregation. Supports glob syntax (e.g., /var/log/*.log). One of --log-file, --syslog, or --authlog must be provided."
  >&2 echo -e "  --disable-cpu-metrics\t\tWhen passed in, detailed CPU metrics reporting will be disabled by the agent."
  >&2 echo -e "  --disable-mem-metrics\t\tWhen passed in, detailed memory metrics reporting will be disabled by the agent."
  >&2 echo -e "  --disable-disk-metrics\t\tWhen passed in, detailed disk metrics reporting will be disabled by the agent."
  >&2 echo -e "  --syslog\tWhen passed in, configure log aggregation for syslog entries. One of --log-file, --syslog, or --authlog must be provided."
  >&2 echo -e "  --authlog\tWhen passed in, configure log aggregation for authentication logs. One of --log-file, --syslog, or --authlog must be provided."
  >&2 echo -e "  --log-group-name\tThe name to use for the log group. Required when configuring log files."
  >&2 echo -e "  --log-stream-name\tThe name to use for the log stream. Optional. Default: $DEFAULT_LOG_STREAM_NAME."
  >&2 echo -e "  --os-user\tThe OS user to use when running the agent. Optional. Default: $DEFAULT_OS_USER."
  >&2 echo
  >&2 echo "Example: configure-cloudwatch-agent.sh --syslog --log-group-name syslog=prod-ec2-syslog --extra-log-file nginx-errors=/var/log/nginx/nginx_error.log"
}

function configure_cloudwatch_agent_os_user_config {
  local -r current_config="$1"
  local -r os_user="$2"

  local new_config
  new_config="$(echo "$current_config" | gojq -M "${CONFIG_FILE_OS_USER_ADDR} = \"$os_user\"")"
  echo "$new_config"
}

function configure_cloudwatch_agent_log_config {
  local -r current_config="$1"
  local -r log_file="$2"
  local -r log_group_name="$3"
  local -r log_stream_name="$4"

  local current_file_length
  current_file_length="$(echo "$current_config" | gojq -M "$CONFIG_FILE_COLLECT_LIST_ADDR | length")"

  local new_log_file_config="{\"file_path\": \"$log_file\", \"log_group_name\": \"$log_group_name\"}"
  if [[ -n "$log_stream_name" ]]; then
    new_log_file_config="$(echo "$new_log_file_config" | gojq -M ". + {\"log_stream_name\": \"$log_stream_name\"}")"
  fi

  local new_config
  # Here we append to the collect list array using gojq. Appending to arrays in gojq requires setting the value of the last
  # index (which is what $current_file_length represents) in the array using '|='
  new_config="$(echo "$current_config" | gojq -M "${CONFIG_FILE_COLLECT_LIST_ADDR}[$current_file_length] |= . + $new_log_file_config")"
  echo "$new_config"
}

# Update the pregenerated config.json file to remove metrics based on user selection.
function configure_cloudwatch_metrics {
  local -r current_config="$1"
  local -r disable_cpu_metrics="$2"
  local -r disable_mem_metrics="$3"
  local -r disable_disk_metrics="$4"

  if [[ "$disable_cpu_metrics" == 'false' ]] && [[ "$disable_mem_metrics" == 'false' ]] && [[ "$disable_disk_metrics" == 'false' ]]; then
    log_info 'No metrics disabled: keeping default metrics configuration.'
    echo "$current_config"
    return
  fi

  # Special case: When all disable flags are true, then we need to clear out the metrics key.
  if [[ "$disable_cpu_metrics" == 'true' ]] && [[ "$disable_mem_metrics" == 'true' ]] && [[ "$disable_disk_metrics" == 'true' ]]; then
    log_info "Disabling all metrics collection."
    local new_config
    new_config="$(echo "$current_config" | gojq -M 'del(.metrics)')"
    echo "$new_config"
    return
  fi

  local new_config="$current_config"

  if [[ "$disable_cpu_metrics" == 'true' ]]; then
    new_config="$(echo "$new_config" | gojq -M 'del(.metrics.metrics_collected.cpu)')"
  fi

  if [[ "$disable_mem_metrics" == 'true' ]]; then
    new_config="$(echo "$new_config" | gojq -M 'del(.metrics.metrics_collected.mem)')"
    new_config="$(echo "$new_config" | gojq -M 'del(.metrics.metrics_collected.swap)')"
  fi

  if [[ "$disable_disk_metrics" == 'true' ]]; then
    new_config="$(echo "$new_config" | gojq -M 'del(.metrics.metrics_collected.disk)')"
    new_config="$(echo "$new_config" | gojq -M 'del(.metrics.metrics_collected.diskio)')"
  fi

  echo "$new_config"
}

function parse_args_and_configure_agent {
  local log_group_name
  local -a log_files=()
  local log_stream_name="$DEFAULT_LOG_STREAM_NAME"
  local os_user="$DEFAULT_OS_USER"
  local include_syslog='false'
  local include_authlog='false'
  local disable_cpu_metrics='false'
  local disable_mem_metrics='false'
  local disable_disk_metrics='false'

  while [[ $# -gt 0 ]]; do
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
      --log-file)
        log_files+=("$2")
        shift
        ;;
      --os-user)
        os_user="$2"
        shift
        ;;
      --syslog)
        include_syslog='true'
        ;;
      --authlog)
        include_authlog='true'
        ;;
      --disable-cpu-metrics)
        disable_cpu_metrics='true'
        ;;
      --disable-mem-metrics)
        disable_mem_metrics='true'
        ;;
      --disable-disk-metrics)
        disable_disk_metrics='true'
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

  assert_is_installed 'gojq'

  if [[ "$include_syslog" == 'true' ]]; then
    if os_is_amazon_linux || os_is_centos; then
      log_files+=("$SYSLOG_PATH_AMAZON_LINUX")
    else
      log_files+=("$SYSLOG_PATH_OTHER_LINUX")
    fi
  fi

  if [[ "$include_authlog" == 'true' ]]; then
    if os_is_amazon_linux || os_is_centos; then
      log_files+=("$AUTH_LOG_PATH_AMAZON_LINUX")
    else
      log_files+=("$AUTH_LOG_PATH_OTHER_LINUX")
    fi
  fi

  if (( "${#log_files[@]}" )); then
    assert_not_empty '--log-group-name' "$log_group_name"
  fi

  local current_config
  current_config="$(cat "$AGENT_CONFIG_JSON_PATH")"

  log_info "Configuring CloudWatch Agent to run as OS user $os_user"
  current_config="$(configure_cloudwatch_agent_os_user_config "$current_config" "$os_user")"

  for log_file in "${log_files[@]}"
  do
    log_info "Configuring CloudWatch Agent to forward logs from $log_file to log group $log_group_name and log stream $log_stream_name"
    current_config="$(configure_cloudwatch_agent_log_config "$current_config" "$log_file" "$log_group_name" "$log_stream_name")"
  done

  log_info "Configuring CloudWatch Agent to ship metrics"
  current_config="$(configure_cloudwatch_metrics "$current_config" "$disable_cpu_metrics" "$disable_mem_metrics" "$disable_disk_metrics")"

  log_info "Saving updated config"
  echo "$current_config" > "$AGENT_CONFIG_JSON_PATH"
}

parse_args_and_configure_agent "$@"
