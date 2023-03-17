# Backup Plan Module

This Terraform Module creates the following AWS Backup resources:

1. Backup plans - specifying **how and when** to back things up
1. Resource selections - specifying **which resources** to back up

You associate your plans with a [Backup vault](/modules/backup-vault).

## How do you use this module?

- See the [root README](/README.adoc) for instructions on using Terraform modules.
- See the [examples](/examples) folder for example usage.
- See [variables.tf](./variables.tf) for all the variables you can set on this module.
- See the [backup-vault module](/modules/backup-vault/README.md) for how to configure plans and resource selections.

## What is a Backup Plan?

A backup plan is a policy expression that defines when and how you want to back up your AWS resources. You can assign resources to backup plans, and AWS Backup will automatically back up those resources according to the backup plan. You can define multiple plans with different resources if you have workloads with different backup requirements.

For example, you can create a plan that backs up all resources (e.g., EC2 instances, RDS instances, etc) with a specific tag once every hour. Meanwhile, you might want to create a second
plan that backs up only your DynamoDB tables, selected by explicitly passing their ARNs that is only backed up once per day. Creating multiple plans and vaults allows you to define your
own backup workflow in whichever way makes the most sense for your use case.

Learn more at [the official AWS documentation for Backup plans](https://docs.aws.amazon.com/aws-backup/latest/devguide/about-backup-plans.html).

## What is a Backup selection?

A Backup selection specifies which AWS resources you want AWS Backup to target when your backup plan is run. You can either specify your target resources via tag, or by explicitly passing their ARNs.

## How do you select resources to backup via tag?

To select all EC2 instances, and DynamoDB tables, and EBS volumes, etc, that have the tag `Snapshot:true`, use a `selection_tag` when configuring this module:

```hcl
module "backup_plan" {

  ...

  plans = {
    "tag-based-backup-plan" = {
        rule = {
          target_vault_name = element(module.backup_vault.vault_names, 0),
          schedule = "cron(47 0/1 * * ? *)"
        }
        selection = {
          selection_tag = {
            type = "STRINGEQUALS"
            "key" = "Snapshot"
            "value" = true
          }
        }
    }
  }
}
```

## How do you select resources to backup via ARN?

To select specific AWS resources by ARN, use the `resources` attribute when configuring this module:

```hcl
module "backup_plan" {

  ...

  plans = {
    "tag-based-backup-plan" = {
        rule = {
          target_vault_name = element(module.backup_vault.vault_names, 0),
          schedule = "cron(47 0/1 * * ? *)"
        }
        resources = [
          "arn:aws:ec2:us-east-1:111111111111:instance/i-0fe68bg5e936782fr",
          "arn:aws:ec2:us-east-1:111111111111:instance/i-0be38tg7e937782a3"
        ]
    }
  }
}
```

## How do you troubleshoot Backup jobs?

See [Troubleshooting AWS Backup](/core-concepts.md#troubleshooting-aws-backup) in the core-concepts guide.
