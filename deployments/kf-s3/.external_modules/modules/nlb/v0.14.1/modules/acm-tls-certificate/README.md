# ACM TLS Certificate

This module can be used to issue and validate a free, auto-renewing TLS certificate using [AWS Certificate 
Manager (ACM)](https://aws.amazon.com/certificate-manager/). The module will create the TLS certificate, as well as
the DNS record to validate it, and output the certificate's ARN so you can use it with other resources, such as ALBs,
CloudFront, and API Gateway.




## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [vars.tf](./vars.tf) for all the variables you can set on this module.




## Special handling for use with API Gateway

If you are using this module to create a TLS certificate that will be used with API Gateway, along with a custom 
domain name, then you need to set `run_destroy_check` to true:

```hcl
module "cert" {
  source = "git::git@github.com:gruntwork-io/module-load-balancer.git//modules/acm-tls-certificate?ref=v0.13.2"
  
  # ... other params ommitted ...
  
  run_destroy_check = true
}
```

Without this, `terraform destroy` will fail. This is because you can't delete an ACM cert while it's in use,
deleting a custom domain name mapping for API Gateway takes 10 - 30 minutes, and Terraform only waits a max of 10 
minutes to delete the cert, so it times out and exits with an error every time. The `run_destroy_check` tells this
module to run a script that waits until the cert is no longer in use.

Two notes about this script:

1. You must install the [AWS CLI](https://aws.amazon.com/cli/) to use it.
1. The script is written in Bash, so it will not work on Windows.