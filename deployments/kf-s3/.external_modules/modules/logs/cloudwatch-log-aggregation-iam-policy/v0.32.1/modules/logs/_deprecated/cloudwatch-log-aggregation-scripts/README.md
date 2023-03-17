# CloudWatch Log Aggregation Scripts

The module `cloudwatch-log-aggregation-scripts` has been replaced by the [agents/cloudwatch-agent
module](../../../agents/cloudwatch-agent), which installs the newer Unified CloudWatch agent for metrics and log
aggregation.

To migrate to the `cloudwatch-agent` module:

- In your AMI build script, replace the `gruntwork-install` call from `logs/cloudwatch-log-aggregation-scripts` to
  `agents/cloudwatch-agent`. E.g., if you had:

      gruntwork-install --module-name 'logs/cloudwatch-log-aggregation-scripts' --module-param aws-region=us-east-1 --tag 'v0.27.0' --repo https://github.com/gruntwork-io/terraform-aws-monitoring"

  replace with:

      gruntwork-install --module-name 'agents/cloudwatch-agent' --module-param aws-region=us-east-1 --tag 'v0.27.0' --repo https://github.com/gruntwork-io/terraform-aws-monitoring"

- In your user data boot script, replace the call to `run-cloudwatch-logs-agent.sh` with `configure-cloudwatch-agent.sh`
  and `restart-cloudwatch-agent.sh`. When updating, you will need to pass in `--syslog` and `--authlog` if you wish to
  maintain backward compatibility in the log files that are aggregated. E.g., if you had:

      /etc/user-data/cloudwatch-log-aggregation/run-cloudwatch-logs-agent.sh \
        --log-group-name "$log_group_name" \
        --extra-log-file kern=/var/log/kern.log

  replace with:

      /etc/user-data/cloudwatch-agent/configure-cloudwatch-agent.sh \
        --syslog --authlog --log-file /var/log/kern.log \
        --log-group-name "$log_group_name" --log-stream-name '{instance_id}-syslog'
      /etc/user-data/cloudwatch-agent/restart-cloudwatch-agent.sh
