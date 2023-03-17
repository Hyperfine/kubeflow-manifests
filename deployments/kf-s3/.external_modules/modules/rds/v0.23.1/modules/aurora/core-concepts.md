# Core Aurora Concepts

## What Is Amazon Aurora?

Amazon Aurora is a fully managed relational database engine that's compatible with MySQL and PostgreSQL. The code, tools,
and applications you use today with your existing MySQL and PostgreSQL databases can be used with Aurora. With some
workloads, Aurora can deliver up to five times the throughput of MySQL and up to three times the throughput of PostgreSQL
without requiring changes to most of your existing applications.

## How do you connect to the database?

This module provides the connection details as [Terraform output
variables](https://www.terraform.io/intro/getting-started/outputs.html):

1. **Cluster endpoint**: The endpoint for the whole cluster. You should always use this URL for writes, as it points to
   the primary.
1. **Instance endpoints**: A comma-separated list of all DB instance URLs in the cluster, including the primary and all
   read replicas. Use these URLs for reads (see "How do you scale this DB?" below).
1. **Port**: The port to use to connect to the endpoints above.

For more info, see [Aurora
endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Aurora.html#Aurora.Overview.Endpoints).

You can programmatically extract these variables in your Terraform templates and pass them to other resources (e.g.
pass them to User Data in your EC2 instances). You'll also see the variables at the end of each `terraform apply` call
or if you run `terraform output`.

## How do you scale this database?

- **Storage**: Aurora manages storage for you, automatically growing cluster volume in 10GB increments up to 64TB.
- **Vertical scaling**: To scale vertically (i.e. bigger DB instances with more CPU and RAM), use the `instance_type`
  input variable. For a list of AWS RDS server types, see [Aurora Pricing](http://aws.amazon.com/rds/aurora/pricing/).
- **Horizontal scaling**: To scale horizontally, you can add more replicas using the `instance_count` input variable,
  and Aurora will automatically deploy the new instances, sync them to the master, and make them available as read
  replicas.

For more info, see [Managing an Amazon Aurora DB
Cluster](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Aurora.Managing.html).

## How do you configure this module?

This module allows you to configure a number of parameters, such as backup windows, maintenance window, port number,
and encryption. For a list of all available variables and their descriptions, see [variables.tf](./variables.tf).

## How do you create a cross-region read replica cluster?

After creating a primary cluster, create another cluster in the secondary region and pass the cluster ARN and region of
the primary cluster:
 
```hcl-terraform
module "replica" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/aurora?ref=v1.0.8"
  
  # ... other parameters omitted ...
  
  replication_source_identifier = "arn:aws:rds:us-east-2:123456789012:cluster:example"
  source_region                 = "us-east-2"
}
```

See the example [here](../../examples/aurora-with-cross-region-replica) for more details.

## How do you destroy a cross-region read replica?

You must first promote it to a primary cluster, then destroy it.
You can promote it via the RDS Console (Actions → Promote), or with `aws rds promote-read-replica-db-cluster --db-cluster-identifier <identifier>`. 
After that, run `terraform destroy` as you normally would.

## Known Issues

Requires terraform provider version 1.32 or newer due to the serverless options

### DBInstance not found

As of August 29, 2017, Terraform 0.10.x has an issue where when you apply an RDS Aurora Instance for the first time, you may sometimes receive the following error:

```
aws_rds_cluster.cluster_with_encryption: Error modifying DB Instance aurora-test: DBInstanceNotFound: DBInstance not found: aurora-test
status code: 404, request id: 040094aa-8c62-11e7-baa6-0d7ac77494f1
```

This error occurs because Terraform first creates the database cluster, then creates one or more database instances, and then queries the AWS API for the IDs of those database instances. But Terraform does not wait long enough for the AWS API to propagate these instances to all AWS API endpoints, so AWS initially replies that the given database instance name was not found.

Fortunately, this issue has a simple fix. After waiting a few seconds, the AWS API will not return the database instances that we expect, so simply re-run `terraform apply` and the operation should complete successfully.

## Limitations with Aurora Serverless

The following limitations apply to Aurora Serverless :

- The port number for connections must be:
  - `3306` for Aurora MySQL
  - `5432` for Aurora PostgreSQL
- You can't give an Aurora Serverless DB cluster a public IP address. You can access an Aurora Serverless DB cluster only from within a virtual private cloud (VPC) based on the Amazon VPC service.
- A connection to an Aurora Serverless DB cluster is closed automatically if it stays open for longer than one day.
- Aurora Replicas
- Amazon RDS Performance Insights

For more info on limitations, see [Limitations of Aurora Serverless](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless.html#aurora-serverless.limitations).
