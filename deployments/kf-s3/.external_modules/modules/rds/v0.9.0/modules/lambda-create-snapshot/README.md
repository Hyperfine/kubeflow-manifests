# Create Snapshot Lambda Module

This module creates an [AWS Lambda](https://aws.amazon.com/lambda/) function that runs periodically and takes snapshots 
of an [Amazon Relational Database (RDS)](https://aws.amazon.com/rds/) database. The lambda function can also optionally 
a) trigger the lambda function in the [lambda-share-snapshot module](/modules/lambda-share-snapshot) to share the 
snapshot with another AWS account and b) report a custom metric to [CloudWatch](https://aws.amazon.com/cloudwatch/), 
which you can use to alert you if the backup job fails.

Note that RDS comes with nightly snapshots by default. The main reason to use this function is:

1. You want to take snapshots of your database more often than once per night.
1. You want to store all of your snapshots in a separate AWS account for security and redundancy purposes.

Note that to use this module, you must have access to the Gruntwork [Continuous Delivery Infrastructure Package 
(module-ci)](https://github.com/gruntwork-io/module-ci). If you need access, email support@gruntwork.io.




## How do you use this module?

See the [lambda-rds-snapshot example](/examples/lambda-rds-snapshot) for sample code. 

If you are using this function to copy snapshots to another AWS account, you may also want to look at the 
[lambda-share-snapshot](/modules/lambda-share-snapshot) and 
[lambda-copy-shared-snapshot](/modules/lambda-copy-shared-snapshot) modules.



## How do you configure this module?

This module allows you to configure a number of parameters, such as which database to backup, how often to run the 
backups, what account to share the backups with, and more. For a list of all available variables and their 
descriptions, see [vars.tf](./vars.tf).



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
      source = "git::git@github.com:gruntwork-io/module-data-storage.git//modules/data-storage/lambda-create-snapshot?ref=v1.0.8"
 
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
      source = "git::git@github.com:gruntwork-io/module-data-storage.git//modules/data-storage/lambda-copy-shared-snapshot?ref=v1.0.8"
 
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



