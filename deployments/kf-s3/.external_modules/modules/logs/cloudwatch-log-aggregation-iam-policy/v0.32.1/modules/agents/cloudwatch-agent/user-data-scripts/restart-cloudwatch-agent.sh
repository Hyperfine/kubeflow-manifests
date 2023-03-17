#!/bin/bash
#
# A convenience wrapper around amazon-cloudwatch-agent-ctl to simplify restarting the amazon-cloudwatch-agent on an EC2
# instance.
#

readonly AGENT_CONFIG_JSON_PATH='/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json'
readonly TMP_AGENT_CONFIG_JSON_PATH='/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json.backup'

# The amazon-cloudwatch-agent-ctl process overwrites the json file so we need to temporarily save it
echo "Backing up agent config"
cp "$AGENT_CONFIG_JSON_PATH" "$TMP_AGENT_CONFIG_JSON_PATH"

echo "Restarting agent process"
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:"$AGENT_CONFIG_JSON_PATH"

echo "Restoring agent config"
cp "$TMP_AGENT_CONFIG_JSON_PATH" "$AGENT_CONFIG_JSON_PATH"
