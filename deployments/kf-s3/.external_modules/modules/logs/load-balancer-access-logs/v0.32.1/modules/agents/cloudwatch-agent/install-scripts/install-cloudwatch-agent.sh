#!/bin/bash
#
# Script that installs the CloudWatch Unified Agent on an EC2 Instance.
#

set -e

readonly BASH_COMMONS_DIR="/opt/gruntwork/bash-commons"
if [[ ! -d "$BASH_COMMONS_DIR" ]]; then
  >&2 echo "ERROR: This script requires that bash-commons is installed in $BASH_COMMONS_DIR. See https://github.com/gruntwork-io/bash-commons for more info."
  exit 1
fi

source "$BASH_COMMONS_DIR/log.sh"
source "$BASH_COMMONS_DIR/assert.sh"
source "$BASH_COMMONS_DIR/os.sh"

readonly SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

readonly AGENT_CONFIG_JSON_PATH='/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json'

function print_usage {
  >&2 echo
  >&2 echo "Usage: install-cloudwatch-agent.sh [OPTIONS]"
  >&2 echo
  >&2 echo "Installs the CloudWatch Logs Agent on an EC2 Instance."
  >&2 echo
  >&2 echo "Options:"
  >&2 echo
  >&2 echo -e "  --aws-region\t\t\tThe AWS region the instance will run in (e.g. us-east-1). Required."
  >&2 echo -e "  --help\t\t\tPrint this help text and exit."
  >&2 echo
  >&2 echo "Example:"
  >&2 echo
  >&2 echo "  install-cloudwatch-agent.sh --aws-region us-east-1"
}

function curl_exec {
  curl --silent --location --fail --show-error "$@"
}

# Get the architecture string associated with the instance. Used to set the architecture string for download links.
# Note: aarch64 is the string used by AWS Graviton processors, but most software uses the more common "arm64" string.
function get_arch {
  local arch="$(uname -m)"

  if [[ "$arch" == "aarch64" ]]; then
    echo "arm64"
  elif [[ "$arch" == "x86_64" ]]; then
    echo "amd64"
  else
    log_error "Unexpected architecture $arch. CloudWatch Agent can be installed on arm64 and amd64 systems."
    exit 1
  fi
}

# gojq is an implementation of jq in go. As of November 2021, jq appears to be abandoned. There are no arm64 binaries
# available, which are needed by AWS Graviton instances.
function install_gojq {
  log_info 'Installing gojq'
  gojq_version="v0.12.5"

  local -r arch="$(get_arch)"

  tmpdir="$(mktemp -d)"
  curl_exec -o "$tmpdir/gojq.tar.gz" "https://github.com/itchyny/gojq/releases/download/$gojq_version/gojq_${gojq_version}_linux_${arch}.tar.gz"
  tar -C "$tmpdir" -xzf "$tmpdir/gojq.tar.gz" "gojq_${gojq_version}_linux_${arch}/gojq"
  sudo mv "${tmpdir}/gojq_${gojq_version}_linux_${arch}/gojq" /usr/local/bin/gojq
  rm -rf "$tmpdir"
}

# On Amazon Linux 2, we need to use yum to install the agent and create a config file in the right location. For more
# info, see https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-on-EC2-Instance.html
function install_agent_on_amazon_linux_2 {
  local -r aws_region="$1"
  log_info 'Installing CloudWatch Logs Agent on Amazon Linux 2'

  sudo yum update -y
  sudo yum install -y amazon-cloudwatch-agent
}

# On Amazon Linux 1, we need to use the RPM package from S3 as it is not available in the yum repositories.
function install_agent_on_amazon_linux_1 {
  local -r aws_region="$1"
  log_info 'Installing CloudWatch Logs Agent on Amazon Linux'
  install_from_s3 "$aws_region" 'amazon_linux' 'rpm'
}

# On non-AL distros, we need to download the specific package for the OS distro from S3 and install it using the
# specific package manager.
# See https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/download-cloudwatch-agent-commandline.html for
# more info.
function install_from_s3 {
  local -r aws_region="$1"
  local -r osdistro="$2"
  local -r package_ext="$3"

  local -r arch="$(get_arch)"

  local -r s3_url="https://s3.$aws_region.amazonaws.com/amazoncloudwatch-agent-$aws_region/$osdistro/$arch/latest/amazon-cloudwatch-agent.$package_ext"

  curl_exec -O "$s3_url"

  if [[ "$package_ext" == 'rpm' ]]; then
    sudo rpm -U ./"amazon-cloudwatch-agent.$package_ext"
  elif [[ "$package_ext" == 'deb' ]]; then
    sudo dpkg -i -E "amazon-cloudwatch-agent.$package_ext"
  else
    log_error "Package extension $package_ext not supported for install by s3."
    exit 1
  fi
}

# See install_from_s3 for info on how to install on CentOS.
function install_agent_on_centos {
  local -r aws_region="$1"
  log_info 'Installing CloudWatch Logs Agent on CentOS'
  install_from_s3 "$aws_region" 'centos' 'rpm'
}

# See install_from_s3 for info on how to install on Ubuntu.
function install_agent_on_ubuntu {
  local -r aws_region="$1"
  log_info 'Installing CloudWatch Logs Agent on Ubuntu'
  install_from_s3 "$aws_region" 'ubuntu' 'deb'
}

# Upload a pregenerated config.json file and runtime scripts for running the agent on EC2 instances. See
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-cloudwatch-agent-configuration-file.html for
# more info on how to generate this config.json file.
function copy_runfiles {
  sudo cp "$SCRIPT_PATH"/config.json "$AGENT_CONFIG_JSON_PATH"

  # Move the user-data files into /etc/user-data
  sudo mkdir -p /etc/user-data/cloudwatch-agent
  sudo cp "${SCRIPT_PATH}"/../user-data-scripts/* /etc/user-data/cloudwatch-agent/
  sudo chmod +x /etc/user-data/cloudwatch-agent/*.sh
}

function run_install {
  local aws_region=''

  while [[ $# -gt 0 ]]; do
    local key="$1"

    case "$key" in
      --aws-region)
        aws_region="$2"
        shift
        ;;
      --help)
        print_usage
        exit
        ;;
      *)
        log_error "Unrecognized argument: $key"
        print_usage
        exit 1
        ;;
    esac

    shift
  done

  assert_not_empty "--aws-region" "$aws_region"

  # See http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/QuickStartEC2Instance.html for the differences
  # between Amazon Linux and other Linux flavors.
  if os_is_amazon_linux 2; then
    install_agent_on_amazon_linux_2 "$aws_region"
  elif os_is_amazon_linux; then
    install_agent_on_amazon_linux_1 "$aws_region"
  elif os_is_centos; then
    install_agent_on_centos "$aws_region"
  elif os_is_ubuntu; then
    install_agent_on_ubuntu "$aws_region"
  else
    log_error "Unrecognized OS - this script only supports Amazon Linux, CentOS, and Ubuntu."
    exit 1
  fi

  # Install gojq, which is used by the configure-cloudwatch-agent.sh script.
  install_gojq

  copy_runfiles
}

run_install "$@"
