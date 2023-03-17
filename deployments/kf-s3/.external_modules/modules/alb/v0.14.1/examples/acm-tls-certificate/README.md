# ACM TLS Certificate Example

This folder shows an example of how to issue and validate a TLS certificate using AWS Certificate Manager (ACM) using
the [acm-tls-certificate module](/modules/acm-tls-certificate) and how to attach that TLS certificate as well as a 
domain name to an Application Load Balancer (ALB).

## How do you run this example?

1. Install [Terraform](https://www.terraform.io/)
1. Open `vars.tf` and fill in the variable values.
1. Run `terraform init`.
1. Run `terraform apply`.