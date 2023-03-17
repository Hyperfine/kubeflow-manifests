# Backup vault with notifications example

This folder contains an example of how to use the [backup-vault module](/modules/backup-vault/README.md) to create an [Amazon
Backup](https://aws.amazon.com/backup) vault, and to enable notifications on the vault.

Backup vault notifications allow vaults to publish events to an SNS topic, so that you can closely monitor the progress and success of
your backup jobs.

Once configured, AWS Backup is capable of perpetually backing up the resources you specify on the schedules you define, so that your data
is secure and you have multiple points of recovery you can restore from.

## How do you run this example?

To run this example, you need to:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults.
1. `terraform init`.
1. `terraform plan`.
1. If the plan looks good, run `terraform apply`.

When the templates are applied, Terraform will output the details of the backup plans and selections that were created.
