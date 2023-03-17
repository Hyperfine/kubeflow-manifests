#!/bin/bash
#
# Script that installs scripts that provide monitoring and disk usage metrics in CloudWatch. For more info, see
# http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts.html
#

set -e

readonly MONITORING_SCRIPT_PATH="/opt/aws-scripts-mon/mon-put-instance-data.pl"
readonly CRONTAB_PATH="/tmp/cloudwatch-monitoring-crontab"
readonly MONITORING_CACHE_TMP_PATH="/var/tmp/aws-mon/"

# If you change these defaults, make sure to update the README too
readonly DEFAULT_METRICS_TO_MONITOR="--disk-path='/' --mem-util --disk-space-util --auto-scaling"
readonly DEFAULT_CRON_SCHEDULE="*/5 * * * *"
readonly DEFAULT_CRON_USER="cwmonitoring"

function print_usage {
  echo
  echo "Usage: install-cloudwatch-monitoring-scripts.sh [OPTIONS]"
  echo
  echo "Installs scripts that provide monitoring and disk usage metrics in CloudWatch."
  echo
  echo "Options:"
  echo
  echo -e "  --cron-schedule\t\t\tThe schedule on which metrics will be sent to CloudWatch in Cron format. Default: $DEFAULT_CRON_SCHEDULE"
  echo -e "  --cron-user\t\t\tThe user account to add and run the CloudWatch metrics script under. Default: $DEFAULT_CRON_USER"
  echo -e "  --metrics-to-monitor\t\t\tA space-separated list of command line options to the CloudWatch Monitoring Scripts that identify the metrics you want monitored. Default: $DEFAULT_METRICS_TO_MONITOR"
  echo -e "  --help\t\t\tPrint this help text and exit."
  echo
  echo "Example:"
  echo
  echo "  install-cloudwatch-monitoring-scripts.sh --cron-schedule \"0 * * * *\" --metrics-to-monitor \"--disk-path='/foo' --disk-space-util --mem-util --mem-used --mem-avail\""
}

function install_dependencies_amazon_linux {
  echo "Installing dependencies on Amazon Linux"
  sudo yum -y update
  sudo yum -y install perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64
}

function install_dependencies_red_hat {
  echo "Installing dependencies on Red Hat"
  sudo yum -y update
  sudo yum -y install perl-DateTime perl-Sys-Syslog
  sudo yum -y install zip unzip
  sudo yum -y install perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA -y
}

function install_dependencies_ubuntu {
  echo "Installing dependencies on Ubuntu"
  sudo apt-get -y update
  sudo apt-get -y install unzip
  sudo apt-get -y install libwww-perl libdatetime-perl
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

# Returns true (0) if this is a RedHat server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_redhat {
  local readonly version="$1"
  grep -q "Red Hat Enterprise Linux Server release $version" /etc/*release
}

# Returns true (0) if this is an Ubuntu server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_ubuntu {
  local readonly version="$1"
  grep -q "Ubuntu $version" /etc/*release
}

function install_cloudwatch_monitoring_scripts {
  echo "Installing CloudWatch monitoring scripts"

  curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
  unzip -o CloudWatchMonitoringScripts-1.2.2.zip
  rm CloudWatchMonitoringScripts-1.2.2.zip

  sudo cp -a aws-scripts-mon $(dirname "$MONITORING_SCRIPT_PATH")
}

function add_cron_tab {
  local readonly cron_user="$1"
  local readonly cron_schedule="$2"
  local readonly metrics_to_monitor="$3"

  if [ ! -f "$MONITORING_SCRIPT_PATH" ]; then
   echo "ERROR: Could not find script $MONITORING_SCRIPT_PATH. Something must have gone wrong with the install."
   exit 1
  fi

  local readonly monitoring_script_path_absolute=$(readlink -f "$MONITORING_SCRIPT_PATH")
  local readonly cron_entry="$cron_schedule $monitoring_script_path_absolute $metrics_to_monitor --from-cron"

  if ! id "${cron_user}" >/dev/null 2>&1; then
    echo "Adding the user account: $cron_user"
    sudo useradd "${cron_user}"
  fi

  echo "Adding the following crontab to ${cron_user}: $cron_entry"

  if $(sudo crontab -u "${cron_user}" -l >/dev/null 2>&1); then
    sudo crontab -u "${cron_user}" -l > "$CRONTAB_PATH"
  fi

  echo "$cron_entry" >> "$CRONTAB_PATH"
  sudo crontab -u "${cron_user}" "$CRONTAB_PATH"
}

# When the Monitoring Script runs, it caches data about the EC2 Instance its running on. Since this install script is
# usually run at build time (e.g. in a Packer build), we do not want to cache a build server's data, as it will
# interfere with a production server's reporting. Therefore, we delete this cache. For more
# info, see: https://forums.aws.amazon.com/thread.jspa?threadID=117783
function cleanup_monitoring_cache {
  local readonly cache_path="$1"
  echo "Cleaning up monitoring cache files in $cache_path"
  rm -rf "$cache_path"
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

function install {
  local cron_schedule="$DEFAULT_CRON_SCHEDULE"
  local cron_user="$DEFAULT_CRON_USER"
  local metrics_to_monitor="$DEFAULT_METRICS_TO_MONITOR"

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --cron-schedule)
        cron_schedule="$2"
        assert_not_empty "$key" "$cron_schedule"
        shift
        ;;
      --cron-user)
        cron_user="$2"
        assert_not_empty "$key" "$cron_user"
        shift
        ;;
      --metrics-to-monitor)
        metrics_to_monitor="$2"
        assert_not_empty "$key" "$metrics_to_monitor"
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

  if os_is_amazon_linux; then
    install_dependencies_amazon_linux
  elif os_is_redhat || os_is_centos; then
    install_dependencies_red_hat
  elif os_is_ubuntu; then
    install_dependencies_ubuntu
  else
    # TODO: the CloudWatch scripts also support SUSE. We could add it if a client requests it.
    echo "ERROR: This script only supports Amazon Linux, Red Hat, and Ubuntu."
    exit 1
  fi

  install_cloudwatch_monitoring_scripts
  add_cron_tab "$cron_user" "$cron_schedule" "$metrics_to_monitor"
  cleanup_monitoring_cache "$MONITORING_CACHE_TMP_PATH"
}

install "$@"
