# Aurora Module

This module creates an Amazon Relational Database Service (RDS) cluster that runs [Amazon
Aurora](https://aws.amazon.com/rds/aurora/details/). The cluster is managed by AWS and automatically handles leader 
election, replication, failover, backups, patching, and encryption. Aurora is compatible with MySQL 5.6.

## How do you use this module?

See the [Aurora example](/examples/aurora) for an example. 

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

* **Storage**: Aurora manages storage for you, automatically growing cluster volume in 10GB increments up to 64TB.
* **Vertical scaling**: To scale vertically (i.e. bigger DB instances with more CPU and RAM), use the `instance_type` 
  input variable. For a list of AWS RDS server types, see [Aurora Pricing](http://aws.amazon.com/rds/aurora/pricing/).
* **Horizontal scaling**: To scale horizontally, you can add more replicas using the `instance_count` input variable, 
  and Aurora will automatically deploy the new instances, sync them to the master, and make them available as read 
  replicas.

For more info, see [Managing an Amazon Aurora DB
Cluster](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Aurora.Managing.html).

## How do you configure this module?

This module allows you to configure a number of parameters, such as backup windows, maintenance window, port number,
and encryption. For a list of all available variables and their descriptions, see [vars.tf](./vars.tf).

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
