# Postgres RDS Example

This folder contains an example of how to use the [RDS module](/modules/rds) to create an Amazon 
Relational Database Service (RDS) cluster that can run PostgreSQL. The cluster is managed by AWS and
automatically handles leader election, replication, failover, backups, patching, and encryption. 

## How do you run this example?

To run this example, you need to:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults. 
1. `terraform init`.
1. `terraform plan`.
1. If the plan looks good, run `terraform apply`.

When the templates are applied, Terraform will output the IP address of the cluster endpoint (which points to the 
master) and the instance endpoints (which point to the master and all replicas). 
