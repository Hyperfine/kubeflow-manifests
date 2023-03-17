# What is AWS Backup?

![AWS Backup architecture](/_docs/backup-architecture.png)

AWS Backup is a fully-managed, automated and configurable backup service designed to work with your existing AWS resources.

Read more at [the official AWS documentation on Backup](https://aws.amazon.com/backup/).

## Opting-in to AWS Backup

To use AWS Backup to protect some AWS services, you must affirmatively opt in. For example, you must opt in to have AWS Backup manage Amazon EC2 AMIs and Amazon EBS snapshots. Opt-in choices apply to the specific account and AWS Region, so you might have to opt in to multiple Regions using the same account.

Read [how to opt-in to AWS Backup in your account](https://docs.aws.amazon.com/aws-backup/latest/devguide/service-opt-in.html).

## Terraform resources for opting-in to AWS Backup

The official AWS Terraform provider exposes [`aws_backup_region_settings`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_region_settings) that you can use to programmatically opt-in to AWS Backup for a given region. We plan to make this opt-in process more expedient in the future with a custom module that generates the opt-in config for each region in your account that you have enabled.

# Troubleshooting AWS Backup

## How do you find out what AWS Backup is actually doing?

Check your [CloudTrail Event history](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events.html) and filter it down to requests made by `backup.amazonaws.com`. Even if you have not configured specific CloudTrail Trails, your last 90 days of API call history will be available within your account. See which API calls were made and look for the failure reason in the log messages.

## There are errors about authorization, permissions, failure to assume, etc

Most issues come down to permissions / role assumption problems, so double check that `backup.amazonaws.com` can assume the role, and that the role contains all permissions for related `backup` and `backup-storage` actions.

## Your backup jobs run but no resources are backed up

If you have no errors about permissions, but your backup jobs "silently fail" without any resources targeted for backup, triple check your tags, including your casing. Tags are case sensitive!

## I have a different issue

Read [the official AWS Backup troubleshooting guide](https://docs.aws.amazon.com/aws-backup/latest/devguide/troubleshooting.html).
