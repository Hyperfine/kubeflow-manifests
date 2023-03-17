# Data backup core concepts

## How does this differ from RDS automatic snapshots?

Note that RDS comes with nightly snapshots by default. The main reason to use this function is:

1. You want to take snapshots of your database more often than once per night.
1. You want to store all of your snapshots in a separate AWS account for security and redundancy purposes.
1. You want to retain backups for longer than the 35-day limit for automatic snapshots.




## How do you backup your RDS snapshots to a separate AWS account?

One of the main use cases for this module is to be able to store your RDS snapshots in a completely separate AWS account.
That reduces the chances that you, or perhaps an intruder who breaks into your AWS account, can accidentally or
intentionally delete all your snapshots.

Let's say you have an RDS database in account A and you want to store snapshots in account B. To set that up, you need
to do the following:

1. Deploy this lambda function (`lambda-create-snapshot`) and the [lambda-share-snapshot
   lambda function](/modules/lambda-share-snapshot) in account A. Configure this lambda function to trigger the 
   `lambda-share-snapshot` function by setting the following variables:
   
    ```hcl
    module "create_snapshot" {
      source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-create-snapshot?ref=v1.0.8"
 
      # ... (other params ommitted) ...
 
      share_snapshot_with_another_account = true
      share_snapshot_lambda_arn = "(ARN of the lambda-share-snapshot function)"
      share_snapshot_with_account_id = "(The ID of account B)"
    }
    ```
    
1. This will make the snapshots from account A *visible* in account B, but it won't actually copy them into the 
   account. To copy them into account B, deploy the [lambda-copy-shared-snapshot 
   module](/modules/lambda-copy-shared-snapshot) in account B and configure it with the account ID of account A: 
   
    ```hcl
    module "copy_shared_snapshot" {
      source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-copy-shared-snapshot?ref=v1.0.8"
 
      # ... (other params ommitted) ...
 
      rds_db_identifier = "(The identifier of the RDS DB in account A)"
      rds_db_account_id = "(The ID of account A)"
    }
    ```



## Why use lambda functions?

The reason we use lambda functions for handling snapshots is:

1. It's easy to use [scheduled events](http://docs.aws.amazon.com/lambda/latest/dg/with-scheduled-events.html) and
   [schedule expressions](http://docs.aws.amazon.com/lambda/latest/dg/tutorial-scheduled-events-schedule-expressions.html)
   to run a lambda function on a periodic basis that is more reliable than just using cron.

1. You can give your lambda function access to RDS via IAM roles instead of using API keys with an external app.

1. The main use case for these lambda snapshot modules is to copy RDS snapshots to an external AWS account. That means
   you need to run code in multiple accounts. It's easier to deploy the necessary lambda functions in each account
   and give those functions access to RDS via IAM roles than it is to create a CI job that can securely access both
   accounts.




## How do you configure this module?

This module allows you to configure a number of parameters, such as which database to backup, how often to run the 
backups, what account to share the backups with, and more. For a list of all available variables and their 
descriptions, see [variables.tf](./variables.tf).




## How do you configure multiple backup schedules?

You can use this module multiple times by configuring different namespaces for the snapshots, which allows you to have
multiple backup schedules with different retention periods. For example you could keep hourly backups for three days,
and weekly backups for one year by configuring two instances of this modules.

```hcl
module "create_daily_snapshot" {
    source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-create-snapshot?ref=v1.0.8"

    # ... (other params omitted) ...

    lambda_namespace    = "${var.rds_db_identifier}-create-weekly-snapshot"
    snapshot_namespace  = "daily"
    schedule_expression = "rate(1 day)"
}

module "create_weekly_snapshot" {
    source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-create-snapshot?ref=v1.0.8"

    # ... (other params omitted) ...
    lambda_namespace    = "${var.rds_db_identifier}-create-weekly-snapshot"
    snapshot_namespace  = "weekly"
    schedule_expression = "rate(1 week)"
}
```

Configure sharing in the same way as described earlier. Only the snapshots from the module with sharing enabled will be
copied.

It's important to use both snapshot and lambda namespaces in all instances to avoid ambiguity for the
[lambda-cleanup-snapshots](../lambda-cleanup-snapshots) module. The
[lambda-cleanup-snapshots](../lambda-cleanup-snapshots) module can be configured with a `snapshot_namespace` too so
different retention periods can be configured for each set of snapshots. See the
[lambda-rds-snapshot-multiple-schedules](../../examples/lambda-rds-snapshot-multiple-schedules) example.
