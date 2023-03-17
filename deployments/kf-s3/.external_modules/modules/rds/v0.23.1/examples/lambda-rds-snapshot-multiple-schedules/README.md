# RDS Lambda Snapshot Multiple Schedules Example

This folder contains examples of how to configure multiple snapshot schedules using:
 
1. The [lambda-create-snapshot module](/modules/lambda-create-snapshot) to take periodic snapshots of an RDS DB, once weekly and once hourly.
1. The [lambda-cleanup-snapshots module](/modules/lambda-cleanup-snapshots) to delete old snapshots with two different retention periods.

Note that to use this module, you must have access to the Gruntwork [Continuous Delivery Infrastructure Package 
(terraform-aws-ci)](https://github.com/gruntwork-io/terraform-aws-ci). If you need access, email support@gruntwork.io.




## How do you run this example?

To run this example, you need to:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults.
1. `terraform init`.
1. `terraform plan`.
1. If the plan looks good, run `terraform apply`.

