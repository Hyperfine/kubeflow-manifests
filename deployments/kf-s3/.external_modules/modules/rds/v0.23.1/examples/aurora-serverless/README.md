# Aurora Serverless Example

This folder contains an example of how to use the [Aurora module](/modules/aurora/README.adoc) to create an Amazon
Relational Database Service (RDS) cluster that runs [Amazon
Aurora Serverless](https://aws.amazon.com/rds/aurora/serverless/). The cluster is managed by AWS and automatically
handles automatic failover, backups, patching, and encryption. Aurora Serverless is compatible with MySQL and Postgres
and because storage and processing are separate, you can scale down to zero processing and pay only for storage.

## How do you run this example?

To run this example, you need to:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults.
1. `terraform init`.
1. `terraform plan`.
1. If the plan looks good, run `terraform apply`.

When the templates are applied, Terraform will output the IP address of the cluster endpoint (which points to the
master).
