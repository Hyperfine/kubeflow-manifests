# Log modules

This folder contains modules that help with logging:

* [cloudwatch-log-aggregation-iam-policy](./cloudwatch-log-aggregation-iam-policy): A module that defines
  an IAM policy that allows reading/writing CloudWatch log data.
* [cloudwatch-log-aggregation-scripts](./cloudwatch-log-aggregation-scripts): Scripts to install and
  configure the CloudWatch Logs Agent.
* [cloudwatch-logs-metric-filters](./cloudwatch-logs-metric-filters): A Terraform module to send alerts when patterns are matched in CloudWatch Logs groups.
* [load-balancer-access-logs](./load-balancer-access-logs): Creates an S3 bucket to store ELB access logs, along with the appropriate access policy and lifecycle rules.
* [syslog](./syslog): Configures rate limiting and log rotation for syslog.

Click on each module above to see its documentation. Head over to the [examples folder](/examples) for examples.
