# Simple Queuing Service (SQS) FIFO and Encrypted Queue Example

This folder shows an example of how to use the [sqs module](/modules/sqs) to create a fifo queue that uses KMS
encryption.

## Quick start

To try these templates out you must have Terraform installed:

1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
