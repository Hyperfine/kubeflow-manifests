# Backup Vault Module

This Terraform Module launches a [Backup Vault](https://docs.aws.amazon.com/aws-backup/latest/devguide/vaults.html) that you can use to store, organize and, optionally, preserve your AWS Backup recovery points against deletion.

## How do you use this module?

- See the [root README](/README.adoc) for instructions on using Terraform modules.
- See the [examples](/examples) folder for example usage.
- See [variables.tf](./variables.tf) for all the variables you can set on this module.
- See the [backup-plan module](/modules/backup-plan/README.md) for how to configure plans and resource selections.

## What is a Backup Vault?

A backup vault is a container for securing and organizing your Backup artifacts, such as EC2 AMIs, RDS Database recovery points, EBS volumes, et cetera. You can specify an AWS KMS key ID that will be used to encrypt resources in this vault that support encryption. Learn more in [the official AWS Backup encryption guide](https://docs.aws.amazon.com/aws-backup/latest/devguide/encryption.html).

Note that, once you have enabled AWS Backup support in a given region for your account, there will always be a default vault named `"Default"` (note the casing). You cannot delete the default backup vault.

You can opt to either associate Backup plans and selections with your default vault, or any custom vaults you create.

## What is a Backup Vault Lock?

Locks are an optional means of adding an additional layer of protection for your recovery points stored in a Backup Vault. If you opt to lock a vault, you will secure its recovery points against delete operations and any updates that would otherwise alter their retention period. This means you can use locks to enforce retention periods, prevent early or accidental deletions by privileged users, and generally meet any compliance and data protection requirements you may have.

See [the official AWS Backup Vault Lock guide](https://docs.aws.amazon.com/aws-backup/latest/devguide/vault-lock.html) for more information.

## How do you lock a vault?

To add a Vault lock when configuring a new vault with this module, set the `locked` attribute to true like so:

```hcl
module "backup_vault" {

  vaults = {
    locked-vault = {
      locked              = true
      changeable_for_days = 5
      min_retention_days  = 30
      max_retention_days  = 120
    }
  }
}
```

## How do you enable vault notifications?

Backup vaults can publish notifications to an SNS topic. This is useful when you want to monitor for any problems with your backup workflows. To enable notifications for a vault when configuring a new vault with this module, set the `enable_notifications` attribute to true like so:

```hcl
module "backup_vault" {

  ...

  vaults = {
    "vault-with-notifications-enabled" = {
        enable_notifications = true
        # If you wish to specify which AWS Backup events to listen to, you can pass them like so
        # If you do not pass events_to_listen_for, then all AWS Backup events will be listened for!
        events_to_listen_for = ["BACKUP_JOB_STARTED", "BACKUP_JOB_COMPLETED"]
    }
  }
}

```

## WARNING - It is important to understand that misuse of locks could lead to high AWS spend

For example, the following common conditions could all be true when you are developing against or testing AWS Backup. If:

1. You create a lock for a vault
1. the vault has a plan selecting many resources, for example, via widely used tags such as `Snapshot: true`
1. Your account has many resources with matching tags
1. Your lock takes effect, because you did not delete it during the 3 day cool-down period

then you will end up with many potentially large recovery points that you cannot delete and must pay for the storage of. **Use extreme caution when testing, developing or studying!**
