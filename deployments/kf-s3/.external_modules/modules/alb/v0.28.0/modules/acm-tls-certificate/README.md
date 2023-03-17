# ACM TLS Certificate

This module can be used to issue and validate free, auto-renewing TLS certificates using [AWS Certificate 
Manager (ACM)](https://aws.amazon.com/certificate-manager/). It supports issuing and validating multiple ACM certificates.

The module will create the TLS certificates, as well as
the DNS records to validate them, and output the certificates' ARNs so you can use them with other resources, such as ALBs, CloudFront, and API Gateway.


## Understanding how ACM certificates are programmatically requested and verified

This module supports ordering and programmatically validating, via DNS records that are written to a public Route53 zone, ACM certificates.

To understand the Route53 certificate ordering and DNS validation process in more detail, consult [the AWS documentation](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html).
The DNS validation scheme is preferred over the alternative email validation scheme, because the DNS scheme can be orchestrated end to end via Terraform, which this module does for you.

At a high level, the process involves:
1. Requesting a certificate for a given domain name such as example.com.
1. Receiving the challenge records provided by AWS, which ask you to prove ownership of the domain by writing a programmatically generated CNAME record to the Route53 public hosted zone associated with example.com. The provided challenge CNAME record will consist of the CNAME record name and a record value.
1. The Route53 public hosted zone must be created if it does not already exist, so that any records written to it will resolve via external DNS queries.
1. Upon writing the challenge record and its value to the public Route53 hosted zone, programmatically initiate the validation process, whereby AWS will query your Route53 zone for the challenge record, ensure it resolves, and that its value is the exact value supplied in the original challenge. Note that these queries must resolve over public DNS, so you can test them yourself:
 `dig _a79865eb4cd1a6ab990a45779b4e0b96.example.com. cname`
1. Once AWS is able to verify that the records resolve correctly and with the expected values, it will convert your certificate from a `pending` status to an `issued` status.

This module is capable of handling these steps for you, so that you need only supply the correct input map of desired certificates via `var.acm_tls_certificates`.

## How to request wildcard certificates

To provision a wildcard certificate for example.com, you would create the following `acm_tls_certificates` input, using the `subject_alternative_names`
field to specify the domain prefixed with `*.`, e.g., `*.example.com`:

```hcl
# Example of a simple wildcard certificate that protects BOTH example.com and the first level of subdomains
# such as test.example.com, mail.example.com, etc
acm_tls_certificates = {
    "example.com" = {
      subject_alternative_names = ["*.example.com"]
      tags = {
        Environment       = "stage"
        run_destroy_check = true
      }
      create_verification_record = true
      verify_certificate         = true
    }
 }
```
Here's an example of requesting a wildcard certificate for the next level down of subdomains:

```hcl

# Example of provisioning a wildcard certificate that protects BOTH test.example.com and mail.test.example.com,
# db.test.example.com, etc
acm_tls_certificates = {
    "test.example.com" = {
      subject_alternative_names = ["*.test.example.com"]
      tags = {
        Environment       = "stage"
        run_destroy_check = true
      }
      create_verification_record = true
      verify_certificate         = true
    }
 }
```

## Requesting a certificate for a domain that doesn't match its hosted zone name

If you are requesting a a certificate for domain X, but you're attaching it to a hosted zone that is NOT named X you must specify the `hosted_zone_id` of the target hosted zone in the `var.acm_tls_certificates` input.

For example, if you are requesting a certificate for `test-29283.example.com`, but you are attaching it to the public zone named `example.com`, then you MUST provide the `hosted_zone_id` for the example.com public zone in your `var.acm_tls_certificates` input map.

Recall that, because of how the programmatic DNS validation scheme works [outlined above](#understanding-how-acm-certificates-are-programmatically-requested-and-verified), you need the DNS validation challenge records that will be generated for your requessted `test-29283.example.com` to resolve via public DNS queries, and therefore you need to write their records to the `example.com` hosted zone. Therefore you would provide the `hosted_zone_id` of `example.com` in your input map as in the following example:

```
acm_tls_certificates = {
    "test-29283.example.com" = {
      subject_alternative_names = ["*.test.example.com"]
      tags = {
        Environment       = "stage"
        run_destroy_check = true
      }
      create_verification_record = true
      verify_certificate         = true
      # This is the ID of the public zone example.com
      hosted_zone_id = "Z04542822CKAS2ZFBUGT"
    }
 }
```

## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [vars.tf](./vars.tf) for all the variables you can set on this module.




## Special handling for use with API Gateway

If you are using this module to create a TLS certificate that will be used with API Gateway, along with a custom 
domain name, then you need to set a tag named exactly `run_destroy_check` with a value of `true`. Do this for every certificate you configure that will be used in this way:  

```hcl
module "cert" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-load-balancer.git//modules/acm-tls-certificate?ref=v0.13.2"
  
  # ... other params ommitted ...
  
  acm_tls_certificates = {
    "mail.example.com" = {
      subject_alternative_names = ["mailme.example.com"]
      tags = {
        Environment       = "stage"
        run_destroy_check = true
      }
      create_verification_record = true
      verify_certificate         = true
    }
    "admin.example.com" = {
      subject_alternative_names = ["restricted.example.com"]
      tags = {
        Something       = "else"
        run_destroy_check = true
      }
      create_verification_record = true
      verify_certificate         = true
    }
  }
  
  # ... other params ommitted ...
}
```

Without this, `terraform destroy` will fail. This is because you can't delete an ACM cert while it's in use,
deleting a custom domain name mapping for API Gateway takes 10 - 30 minutes, and Terraform only waits a max of 10 
minutes to delete the cert, so it times out and exits with an error every time. The `run_destroy_check` tells this
module to run a script that waits until the cert is no longer in use.

Two notes about this script:

1. You must install the [AWS CLI](https://aws.amazon.com/cli/) to use it.
1. The script is written in Bash, so it will not work on Windows versions earlier than Windows 10, which supports a Linux Bash shell. 

## A note on the dependency_getter pattern implementing module_depends

This module uses a [null_resource](https://github.com/gruntwork-io/terraform-aws-load-balancer/blob/master/modules/acm-tls-certificate/main.tf#L15) named `dependency_getter` to effectively implement `depends_on` at the module level. This is a temporary workaround as Terraform does not yet natively support `depends_on` at the module level. You can also see [this Terraform issue on GitHub](https://github.com/hashicorp/terraform/issues/1178) for more discussion.

Here's how this works. First, we create [this optional dependencies variable](https://github.com/gruntwork-io/terraform-aws-load-balancer/blob/master/modules/acm-tls-certificate/vars.tf#L124) for the current module, which accepts a list of strings, but defaults to an empty list. The `null_resource` linked above does a simple join on the dependencies list, if present. Every resource within this module also `depends_on` this `null_resource.dependency_getter`(even though it's creating no resources). 

This has the desirable effect of causing the dependency graph that Terraform builds to look as you'd expect if there were in fact native support for `depends_on` at the module level. Let's say you had a separate Terraform module that needed to consume this current module in order to generate certificates, but you wanted this certificates module to wait to do any of its work until some of the outputs from the resources in your parent module were ready. In that case, you could pass those outputs into this module's `dependencies` variable, like so: 

```
# ---------------------------------------------------------------------------------------------------------------------
# CREATE PUBLIC HOSTED ZONE(S)
# ---------------------------------------------------------------------------------------------------------------------

module "acm-tls-certificates" {
  # When using these modules in your own repos, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-load-balancer.git//modules/acm-tls-certificate?ref=v0.19.0"

  source               = "git::git@github.com:gruntwork-io/terraform-aws-load-balancer.git//modules/acm-tls-certificate?ref=v0.20.0"
  acm_tls_certificates = local.acm_tls_certificates

  # Workaround Terraform limitation where there is no module depends_on.
  # See https://github.com/hashicorp/terraform/issues/1178 for more details.
  # This effectively draws an explicit dependency between the public 
  # and private zones managed here and the ACM certificates that will be optionally 
  # provisioned for them 
  dependencies = flatten([values(aws_route53_zone.public_zones).*.name_servers])
}
```
In this example, the `acm-tls-certificates` module will "wait" until your `aws_route53_zone.public_zones` resources have been successfully provisioned.
