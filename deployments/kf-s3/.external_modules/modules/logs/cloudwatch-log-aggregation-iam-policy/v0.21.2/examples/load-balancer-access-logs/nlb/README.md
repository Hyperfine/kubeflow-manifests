# NLB Access Logs Example

This is an example of how to configure a Network Load Balancer (NLB) so that it stores its access logs in an S3
bucket using the following modules:

* [load-balancer-access-logs](/modules/logs/load-balancer-access-logs): Creates an S3 bucket to store ALB access logs, along with the
  appropriate access policy and lifecycle rules.

## Quick start

To try these templates out you must have Terraform installed (minimum version: `0.6.11`):

1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including setting `ami` to the AMI you built in step 1.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

## Viewing and Accessing Log Files

See the [Module README](../../../modules/logs/load-balancer-access-logs/README.md) for additional details.
