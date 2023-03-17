#!/usr/bin/env bash
#
# Script used by gruntwork-install to install the cloudwatch-memory-disk-metrics module.
#

set -e

# Locate the directory in which this script is located
readonly script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the install script
chmod u+x "${script_path}/install-scripts/install-cloudwatch-monitoring-scripts.sh"
"${script_path}/install-scripts/install-cloudwatch-monitoring-scripts.sh" "$@"
