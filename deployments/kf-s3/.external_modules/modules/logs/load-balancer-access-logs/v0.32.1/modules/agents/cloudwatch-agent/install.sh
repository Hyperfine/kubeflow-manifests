#!/usr/bin/env bash
#
# Script used by gruntwork-install to install the cloudwatch-agent module.
#

set -e

# Locate the directory in which this script is located
readonly SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the install script
chmod u+x "${SCRIPT_PATH}/install-scripts/install-cloudwatch-agent.sh"
"${SCRIPT_PATH}/install-scripts/install-cloudwatch-agent.sh" "$@"
