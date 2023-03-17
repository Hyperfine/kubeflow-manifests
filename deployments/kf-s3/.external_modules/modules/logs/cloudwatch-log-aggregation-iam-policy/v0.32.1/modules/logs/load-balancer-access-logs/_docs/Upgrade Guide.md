# Upgrade Guide

This guide describes how to upgrade from previous versions of this module.

## Upgrading From the `elb-access-logs` Module

When upgrading from the old `elb-access-logs` module, use the following steps:

1. Change the `source` property to point to the new module. For example:

   ```hcl-terraform
    source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/load-balancer-access-logs?ref=vX.Y.Z"
    ```

1. Change some of the old parameters to the parameters of the `load-balancer-access-logs` module:

   - Rename the `bucket_name` property to `s3_bucket_name`.
   - Rename the `app_name` property to `s3_logging_prefix`.
   - In both cases you may leave the values unchanged.
   - By default, ELB logs will be archived for 30 days and never deleted. Consider changing these preferences by explicitly
     setting the properties `num_days_after_which_archive_log_data` and `num_days_after_which_delete_log_data`.
   
1. Replace all instances of the the old module output `s3_bucket_id` with `s3_bucket_name`.  
   - For example, look for a module output value named something `module.elb_access_logs_bucket.s3_bucket_id` and change it to 
     `module.elb_access_logs_bucket.s3_bucket_name`. Note that your instance of the module may have a different name
     other than `elb_access_logs_bucket`.
   - You should look both in `main.tf` and `outputs.tf`.

1. Run `terragrunt get -update` to download the newest module.

1. Run `terragrunt plan` to confirm that Terraform wants to destroy the old S3 bucket and create a new one. You should 
   see an output similar to the following:
   
   ```
   - module.elb_access_logs_bucket.aws_s3_bucket.access_logs
   
   + module.elb_access_logs_bucket.aws_s3_bucket.access_logs_with_logs_archived
       acceleration_status:                                                 "<computed>"
       ...
   ```

1. Help Terraform recognize it can just use a "modify" operation on the S3 Bucket rather than a "destroy and re-create"
   options by updating the Terraform state.
   - Let's call the `-` module above `<old-module>` and the `+` module above `<new-module>`.
   - Run the following command to update the Terraform state:
   
     ```
     terraform state mv <old-module> <new-module>
     ```
     
     For example, using the Terraform plan output from the previous step, you would use this command:
     
     ```
     terraform state mv module.elb_access_logs_bucket.aws_s3_bucket.access_logs module.elb_access_logs_bucket.aws_s3_bucket.access_logs_with_logs_archived
     ```
   
1. Run `terragrunt plan` to validate that a modify operation will take place. Your plan output should look something like this:

   ```
   ~ module.elb_access_logs_bucket.aws_s3_bucket.access_logs_with_logs_archived
       lifecycle_rule.0.expiration.3591068768.date:                         "" => ""
       ...
   ```

1. If the previous step output matches, run `terragrunt apply` to finalize the change.