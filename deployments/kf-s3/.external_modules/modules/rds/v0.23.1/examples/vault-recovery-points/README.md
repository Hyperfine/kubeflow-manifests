# Custom Backup vault and plan example

This folder contains an example of how to use the [backup-vault module](/modules/backup-vault/README.md) and the [backup-plan](/modules/backup-plan/README.md) to create an [Amazon
Backup](https://aws.amazon.com/backup) vault, and a backup plan with a schedule and resource selection, associated with the custom vault, however its main purpose is to be executed as an end-to-end test of the backup modules.

This example is used by the `example_backup_recovery_point_test.go` test located in the test folder.

## How do you run this example?

To run this example, you need to:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults.
1. `terraform init`.
1. `terraform plan`.
1. If the plan looks good, run `terraform apply`.

When the templates are applied, Terraform will output the details of the backup plans and selections that were created.
