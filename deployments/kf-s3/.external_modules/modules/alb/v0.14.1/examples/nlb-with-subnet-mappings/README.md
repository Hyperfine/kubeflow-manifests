# NLB Example With Subnet Mappings

This folder shows an example of how to launch a standalone Network Load Balancer (NLB) with subnet mappings, which can be used to assign static IPs to the load balancer. Note that in practice, you would usually launch an NLB in conjunction with an EC2 Instance, or Auto Scaling Group.

## How do you run this example?

To run this example, simply apply the Terraform templates.

#### Apply the Terraform templates

To apply the Terraform templates:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `vars.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults.
1. `terraform init`.
1. `terraform apply`.