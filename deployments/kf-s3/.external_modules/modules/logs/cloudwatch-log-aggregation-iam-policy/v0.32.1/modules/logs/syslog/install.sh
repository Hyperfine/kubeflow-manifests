#!/bin/bash
#
# Script used by gruntwork-install to install the syslog module.
#

set -e

# Locate the directory in which this script is located
readonly script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the install script
chmod u+x "${script_path}/install-scripts/configure-syslog"
"${script_path}/install-scripts/configure-syslog" "$@"
