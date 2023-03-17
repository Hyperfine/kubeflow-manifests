# Backup with Default vault example

This folder contains an example of how to use the [backup-vault module](/modules/backup-vault/README.md) to create an [Amazon
Backup](https://aws.amazon.com/backup) plan and associate it with the Default vault in your account. Once configured, AWS Backup is
capable of perpetually backing up the resources you specify on the schedules you define, so that your data is secure and you have multiple
points of recovery you can restore from.

## Understanding Default vaults

When you opt-in to AWS Backup in a given region, a Default Backup vault will be created. The Default vault cannot be deleted. If you don't wish to create
and manage custom vaults for separate backup workflows, you can create plans and schedules and associate them with your Default vault in each region.

To understand more about Default vaults and the opt-in process, see the [backup-vault module' Core concepts document](/modules/backup-vault/README.md)

## How do you run this example?

To run this example, you need to:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults.
1. `terraform init`.
1. `terraform plan`.
1. If the plan looks good, run `terraform apply`.

When the templates are applied, Terraform will output the details of the backup plans and selections that were created.
