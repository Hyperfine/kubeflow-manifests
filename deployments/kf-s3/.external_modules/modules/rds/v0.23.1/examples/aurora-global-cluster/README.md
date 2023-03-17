# Aurora Global Cluster Example

This folder contains an example of how to use the [Aurora Global Cluster module](/modules/aurora/README.adoc) to create an Amazon
Relational Database Service (RDS) cluster that runs [Amazon
Aurora](https://aws.amazon.com/rds/aurora/details/). The cluster is managed by AWS and
automatically handles leader election, replication, failover, backups, patching, and encryption. Aurora is compatible
with MySQL and Postgres.

This example will create a global cluster with the primary aurora cluster in one region (`var.aws_region`), while the
replica cluster is in another region (`var.replica_region`).


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

## Potential Configuration Pitfalls

https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html#aurora-global-database.limitations

1. [EngineMode](https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBCluster.html#API_CreateDBCluster_RequestParameters) - global engine mode only applies for global database clusters created with Aurora MySQL version 5.6.10a. For higher Aurora MySQL versions, the clusters in a global database use provisioned engine mode.
1. [EngineVersion](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Updates.html#AuroraMySQL.Updates.EngineVersions) - Starting with Aurora MySQL 2.03.2, Aurora engine versions have the following syntax. `<mysql-major-version>.mysql_aurora.<aurora-mysql-version>` e.g. `5.7.mysql_aurora.2.08.1`
1. [Instance Type](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html#aurora-global-database.limitations) - You have a choice of using db.r4 or db.r5 instance classes for an Aurora global database. You can't use db.t2 or db.t3 instance classes.
