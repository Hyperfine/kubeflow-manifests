#!/bin/bash
#
# Script that installs the CloudWatch Logs Agent on an EC2 Instance.
#

set -e

readonly AWS_LOGS_CONF_PATH_AMAZON_LINUX="/etc/awslogs/awslogs.conf"
readonly AWS_LOGS_CONF_PATH_OTHER_LINUX="/tmp/awslogs.conf"

readonly LOG_AGENT_STATE_FILE_AMAZON_LINUX="/var/lib/awslogs/agent-state"
readonly LOG_AGENT_STATE_FILE_OTHER_LINUX="/var/awslogs/state/agent-state"

readonly AWS_CLI_CONF_AMAZON_LINUX="/etc/awslogs/awscli.conf"

readonly LOG_AGENT_INSTALL_SCRIPT="awslogs-agent-setup.py"
readonly LOG_AGENT_INSTALL_SCRIPT_URL="https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/$LOG_AGENT_INSTALL_SCRIPT"

function print_usage {
  echo
  echo "Usage: install-cloudwatch-logs-agent.sh [OPTIONS]"
  echo
  echo "Installs the CloudWatch Logs Agent on an EC2 Instance."
  echo
  echo "Options:"
  echo
  echo -e "  --aws-region\t\t\tThe AWS region the instance will run in (e.g. us-east-1). Required."
  echo -e "  --help\t\t\tPrint this help text and exit."
  echo
  echo "Example:"
  echo
  echo "  install-cloudwatch-logs-agent.sh --aws-region us-east-1"
}

# Returns true (0) if this is an Amazon Linux server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_amazon_linux {
  local readonly version="$1"
  grep -q "Amazon Linux * $version" /etc/*release
}

function has_yum {
  [ -n "$(command -v yum)" ]
}

function has_apt_get {
  [ -n "$(command -v apt-get)" ]
}

function has_python {
  [ -n "$(command -v python)" ]
}

function has_pip {
  [ -n "$(command -v pip)" ]
}

function create_aws_cli_config {
  local readonly aws_region="$1"
  local readonly aws_cli_config_path="$2"

  echo "Creating $aws_cli_config_path"
sudo tee "$aws_cli_config_path" > /dev/null << EOF
[plugins]
cwlogs = cwlogs
[default]
region = ${aws_region}
EOF
}

# On Amazon Linux, we need to use yum to install the agent and create a config file in the right location. For more
# info, see http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/QuickStartEC2Instance.html#d0e15036
function install_agent_on_amazon_linux {
  local readonly aws_region="$1"
  echo "Installing CloudWatch Logs Agent on Amazon Linux"

  sudo yum update -y
  sudo yum install -y awslogs
  create_config_file "$LOG_AGENT_STATE_FILE_AMAZON_LINUX" "$AWS_LOGS_CONF_PATH_AMAZON_LINUX"
  create_aws_cli_config "$aws_region" "$AWS_CLI_CONF_AMAZON_LINUX"
}

# On non-Amazon Linux, we update the package manager (in this case yum) to the latest packages and run the Python
# script installer
function install_agent_on_linux_with_yum {
  local readonly aws_region="$1"
  echo "Installing CloudWatch Logs Agent on Linux that has yum installed"

  sudo yum update -y

  if $(! has_python); then
    echo "Installing Python"
    sudo yum install -y python python-setuptools
    sudo easy_install pip
    install_virtualenv
  fi

  install_agent_from_python_script "$aws_region"
}

# On non-Amazon Linux, we update the package manager (in this case apt-get) to the latest packages and run the Python
# script installer
function install_agent_on_linux_with_apt_get {
  local readonly aws_region="$1"
  echo "Installing CloudWatch Logs Agent on Linux that has apt-get installed"

  sudo apt-get update

  if $(! has_python); then
    echo "Installing Python"
    sudo apt-get install -y python python-setuptools python-pip
    install_virtualenv
  fi

  install_agent_from_python_script "$aws_region"
}

function install_virtualenv {
  echo "Installing virtualenv"
  sudo pip install virtualenv

  # This avoids the error "locale.Error: unsupported locale setting" when using virtualenv. For more info, see:
  # http://stackoverflow.com/a/36394262/483528
  export LC_ALL=C
}

# They Python script installer will install the CloudWatch logs agent and run it for you. You just need to give it the
# log config file, which it will copy into the proper destination. For more info, see:
# http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/QuickStartEC2Instance.html#d0e15145
function install_agent_from_python_script {
  local readonly aws_region="$1"

  echo "Installing CloudWatch Logs Agent using Python install script $LOG_AGENT_INSTALL_SCRIPT"
  create_config_file "$LOG_AGENT_STATE_FILE_OTHER_LINUX" "$AWS_LOGS_CONF_PATH_OTHER_LINUX"

  curl "$LOG_AGENT_INSTALL_SCRIPT_URL" -O
  sudo python ./"$LOG_AGENT_INSTALL_SCRIPT" --non-interactive --configfile "$AWS_LOGS_CONF_PATH_OTHER_LINUX" --region "$aws_region"
}

function create_config_file {
  local readonly state_file_path="$1"
  local readonly config_file_path="$2"

  echo "Creating log agent configuration file $config_file_path"

sudo tee "$config_file_path" > /dev/null << EOF
[general]
state_file = $state_file_path
use_gzip_http_content_encoding = true
EOF
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

function run_install {
  local aws_region=""

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --aws-region)
        aws_region=$2
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

  assert_not_empty "--aws-region" "$aws_region"

  # See http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/QuickStartEC2Instance.html for the differences
  # between Amazon Linux and other Linux flavors
  if os_is_amazon_linux; then
    install_agent_on_amazon_linux "$aws_region"
  elif $(has_yum); then
    install_agent_on_linux_with_yum "$aws_region"
  elif $(has_apt_get); then
    install_agent_on_linux_with_apt_get "$aws_region"
  else
    echo "ERROR: Unrecognized OS that is not Amazon Linux, does not have yum, and does not have apt-get."
    exit 1
  fi
}

run_install "$@"
