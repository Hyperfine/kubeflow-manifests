# CloudWatch Log Aggregation Example

This is an example of how to send your log data to CloudWatch Logs using the following modules:

* [cloudwatch-log-aggregation-iam-policy](/modules/logs/cloudwatch-log-aggregation-iam-policy): A module that defines
  an IAM policy that allows reading/writing CloudWatch log data.
* [cloudwatch-log-aggregation-scripts](/modules/logs/cloudwatch-log-aggregation-scripts): Scripts to install and
  configure the CloudWatch Logs Agent.

## Quick start

To try these templates out you must have Terraform installed (minimum version: `0.6.11`):

1. Build an AMI using the [Packer](https://www.packer.io/) template under `packer/build.json`.
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including setting `ami` to the AMI you built in step 1.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

## How do I see the CloudWatch Logs?

Visit the [CloudWatch Logs Dashboard](https://console.aws.amazon.com/cloudwatch/home#logs:) and look for the log group
name `<name>-logs` (e.g. `cloudwatch-log-aggregation-example-logs`).
