#!/usr/bin/env bash
#
# Script used by gruntwork-install to install the cloudwatch-log-aggregation module.
#

set -e

# Locate the directory in which this script is located
readonly script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the install script
chmod u+x "${script_path}/install-scripts/install-cloudwatch-logs-agent.sh"
"${script_path}/install-scripts/install-cloudwatch-logs-agent.sh" "$@"

# Move the user-data files into /etc/user-data
mkdir -p /etc/user-data/cloudwatch-log-aggregation
cp "${script_path}"/user-data-scripts/* /etc/user-data/cloudwatch-log-aggregation/

# Change ownership and permissions  
chmod -R +x /etc/user-data/cloudwatch-log-aggregation