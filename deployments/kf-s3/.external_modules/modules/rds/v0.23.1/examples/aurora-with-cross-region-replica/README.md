# Aurora with Cross-Region Read Replica Example

This folder contains an example of how to use the [Aurora module](/modules/aurora/README.adoc) to create an Amazon 
Relational Database Service (RDS) cluster and cross-region read replica. The cluster is managed by AWS and
automatically handles leader election, replication, failover, backups, patching, and encryption. Aurora is compatible
with MySQL 5.6.

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

## How do you destroy this example?

Read replica clusters must first be promoted before they can be destroyed.
You can promote it via the RDS Console (Actions → Promote), or with `aws rds promote-read-replica-db-cluster --db-cluster-identifier <identifier>`.
After that, run `terraform destroy` as you normally would.