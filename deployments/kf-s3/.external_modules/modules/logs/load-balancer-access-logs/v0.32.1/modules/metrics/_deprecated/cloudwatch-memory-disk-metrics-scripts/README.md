# CloudWatch Memory and Disk Metrics Scripts

The module `metrics/cloudwatch-memory-disk-metrics-scripts` has been replaced by the [agents/cloudwatch-agent
module](../../../agents/cloudwatch-agent), which installs the newer Unified CloudWatch agent for metrics and log
aggregation.

To migrate to the `cloudwatch-agent` module:

- In your AMI build script, replace the `gruntwork-install` call from `metrics/cloudwatch-memory-disk-metrics-scripts` to
  `agents/cloudwatch-agent`. E.g., if you had:

      gruntwork-install --module-name 'metrics/cloudwatch-memory-disk-metrics-scripts' --tag 'v0.27.0' --repo https://github.com/gruntwork-io/terraform-aws-monitoring"

  replace with:

      gruntwork-install --module-name 'agents/cloudwatch-agent' --module-param aws-region=us-east-1 --tag 'v0.27.0' --repo https://github.com/gruntwork-io/terraform-aws-monitoring"

- In your user data boot script, add the following calls:

      /etc/user-data/cloudwatch-agent/configure-cloudwatch-agent.sh --enable-cpu-metrics --enable-mem-metrics --enable-disk-metrics
      /etc/user-data/cloudwatch-agent/restart-cloudwatch-agent.sh

Note that due to changes in the way the agent reports the metrics, they will be available under a different namespace
and name. The metrics will now be available under the namespace `CWAgent` with the following names:

- `mem_cached`
- `mem_total`
- `mem_used`
- `swap_free`
- `swap_used`
- `swap_used_percent`
- `disk_total`
- `disk_free`
- `disk_used`
