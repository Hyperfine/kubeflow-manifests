# Backup vault with lock example

This folder contains an example of how to use the [backup-vault module](/modules/backup-vault/README.md) to create an [Amazon
Backup](https://aws.amazon.com/backup) vault, and then lock that vault, in order to guarantee preservation of any recovery points
that end up stored in the vault. This example will also create a plan and associate it with the newly created, locked vault in your account.
Once configured, AWS Backup is capable of perpetually backing up the resources you specify on the schedules you define, so that your data
is secure and you have multiple points of recovery you can restore from.

# Understanding vault locks

It is important that you first take a moment to understand AWS Backup [vault locks](https://docs.aws.amazon.com/aws-backup/latest/devguide/vault-lock.html) and their behavior. It is strongly encouraged that you read [the official documentation on vault locks](https://docs.aws.amazon.com/aws-backup/latest/devguide/vault-lock.html) first, prior to applying or testing this example.

**If you create a locked vault, and your lock cooling-off period expires without you having deleted the lock, the lock will go into effect. Once your lock goes into effect, you can no longer delete it, or recovery points secured in the locked vault.** This could lead to undesired AWS spend.

## How do you run this example?

To run this example, you need to:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults.
1. `terraform init`.
1. `terraform plan`.
1. If the plan looks good, run `terraform apply`.

When the templates are applied, Terraform will output the details of the backup plans and selections that were created.
