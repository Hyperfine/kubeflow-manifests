# RDS Lambda Snapshot Example

This folder contains examples of how to:
 
1. Use the [lambda-create-snapshot module](/modules/lambda-create-snapshot) to take periodic snapshots of an RDS DB.
1. Use the [lambda-share-snapshot module](/modules/lambda-share-snapshot) to share those snapshots with another AWS 
   account.
1. Use the [lambda-copy-shared-snapshot module](/modules/lambda-copy-shared-snapshot) to make local copies of 
   snapshots from external AWS accounts.
1. Use the [lambda-cleanup-snapshots module](/modules/lambda-share-snapshot) to delete old snapshots.

The code includes examples of Aurora on RDS and MySQL on RDS. 

Note that to use this module, you must have access to the Gruntwork [Continuous Delivery Infrastructure Package 
(terraform-aws-ci)](https://github.com/gruntwork-io/terraform-aws-ci). If you need access, email support@gruntwork.io.




## How do you run this example?

To run this example, you need to:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults. 
1. `terraform get`.
1. `terraform plan`.
1. If the plan looks good, run `terraform apply`.

