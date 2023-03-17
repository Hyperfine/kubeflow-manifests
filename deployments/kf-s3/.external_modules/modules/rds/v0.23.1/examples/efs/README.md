# EFS Example

This folder contains an example of how to use the [EFS module](/modules/efs/README.adoc) to create an Amazon 
Elastic File System (EFS) file system.

## How do you run this example?

To run this example, you need to:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults. 
1. `terraform init`.
1. `terraform plan`.
1. If the plan looks good, run `terraform apply`.

When the templates are applied, Terraform will output the DNS name for connecting to the file system.