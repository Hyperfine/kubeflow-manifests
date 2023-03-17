# ALB with Logs Example

This folder shows an example of how to launch a standalone Application Load Balancer (ALB) with logging enabled. Note 
that in practice, you would usually launch an ALB in conjunction with an ECS Cluster, ECS Service, or Auto Scaling Group.

## How do you run this example?

To run this example, simply apply the Terraform templates.

#### Apply the Terraform templates

To apply the Terraform templates:

1. Install [Terraform](https://www.terraform.io/)
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default. This includes setting the `cluster_instance_ami` the ID of the AMI you just built.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.