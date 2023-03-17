![Terraform Version](https://img.shields.io/badge/tf-%3E%3D1.1.0-blue.svg)

# Load Balancer Modules

This repo contains Gruntwork Modules for running a load balancer in AWS. The modules are:

* **[alb](modules/alb):** Deploy an [Application Load Balancer](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) for use with any [ALB Target
Group](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html).
* **[acm-tls-certificates](modules/acm-tls-certificate):** Issue and validate TLS certificates using [AWS Certificate Manager (ACM)](https://aws.amazon.com/certificate-manager/).
* **[lb-listener-rules](modules/lb-listener-rules):** Simpler and more declarative interface for creating [Load Balancer Listener Rules](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html).

## What about the Classic Load Balancer (CLB) and Network Load Balancer (NLB)?

Note that the [Classic Load Balancer](http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/introduction.html)
(sometimes known by its original name of "ELB") and [Network Load
Balancers](http://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) are usually simple enough
that it is best defined as part of the Terraform template that needs it, so there are currently no plans to define a
standalone "elb" module.

To deploy a classic load balancer, you can use the [aws_elb terraform
resource](https://www.terraform.io/docs/providers/aws/r/elb.html).

To deploy a network load balancer, you can use the [aws_lb terraform
resource](https://www.terraform.io/docs/providers/aws/r/lb.html) with the `load_balancer_type` input set to `"network"`.
You can refer to [the `after_migration` terraform module](./_docs/migration_guides/nlb_to_0.15.0/after_migration) in our
NLB module migration guide for an example of how to configure an NLB using the terraform resources.

## Removed modules

The `nlb` module was removed in version `v0.15.0`. When Terraform introduced `for_each` and dynamic sub blocks in
`v0.12.0`, it no longer made sense to maintain the NLB module which thinly wrapped the `aws_lb` resource to provide
dynamic subnet mappings blocks.

Refer to [the migration guide](./_docs/migration_guides/nlb_to_0.15.0) for information on how to update your
usage.


## What is a module?

At [Gruntwork](http://www.gruntwork.io), we've taken the thousands of hours we spent building infrastructure on AWS and
condensed all that experience and code into pre-built **packages** or **modules**. Each module is a battle-tested,
best-practices definition of a piece of infrastructure, such as a VPC, ECS cluster, or an Auto Scaling Group. Modules
are versioned using [Semantic Versioning](http://semver.org/) to allow Gruntwork clients to keep up to date with the
latest infrastructure best practices in a systematic way.

## How do you use a module?

Most of our modules contain either:

1. [Terraform](https://www.terraform.io/) code
1. Scripts & binaries

#### Using a Terraform Module

To use a module in your Terraform templates, create a `module` resource and set its `source` field to the Git URL of
this repo. You should also set the `ref` parameter so you're fixed to a specific version of this repo, as the `master`
branch may have backwards incompatible changes (see [module
sources](https://www.terraform.io/docs/modules/sources.html)).

For example, to use `v1.0.8` of the ecs-cluster module, you would add the following:

```hcl
module "ecs_cluster" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-ecs.git//modules/ecs-cluster?ref=v1.0.8"

  # set the parameters for the ECS cluster module
}
```

*Note: the double slash (`//`) is intentional and required. It's part of Terraform's Git syntax (see [module
sources](https://www.terraform.io/docs/modules/sources.html)).*

See the module's documentation and `vars.tf` file for all the parameters you can set. Run `terraform get -update` to
pull the latest version of this module from this repo before runnin gthe standard  `terraform plan` and
`terraform apply` commands.

#### Using scripts & binaries

You can install the scripts and binaries in the `modules` folder of any repo using the [Gruntwork
Installer](https://github.com/gruntwork-io/gruntwork-installer). For example, if the scripts you want to install are
in the `modules/ecs-scripts` folder of the https://github.com/gruntwork-io/terraform-aws-ecs repo, you could install them
as follows:

```bash
gruntwork-install --module-name "ecs-scripts" --repo "https://github.com/gruntwork-io/terraform-aws-ecs" --tag "0.0.1"
```

See the docs for each script & binary for detailed instructions on how to use them.

## Background

#### What exactly is a load balancer?

A load balancer is usually the public-facing part of your infrastructure, receives incoming requests, makes a decision 
on which backend service to route them to, and forwards the request. 

Load balancers can forward any kind of IP traffic, including TCP, UDP, HTTP, and HTTPS requests.

#### Why is a load balancer sometimes called a reverse proxy?

A "forward proxy" is a server that forwards incoming requests to an external party on your behalf. For example, a "web
proxy" is a forward proxy that makes HTTP requests on your behalf and forwards you the results. This might be useful if
you want to hide your IP address from websites you request, or if your organization wants to scan all web traffic.

A "reverse proxy" works in the opposite way. An external party makes an inbound request meant for a server, but instead
of hitting that server directly, the request hits the "reverse proxy", which then forwards that request to some unknown
backend service, gets the result, and returns it to a client.

It's conceptually identical to a load balancer, so "load balancer" and "reverse proxy" are synonyms.

#### Why are load balancers needed?

The simplest way to expose a service is to run a single server that runs your service. Users would then make requests 
directly to this server.

This has the benefit of simplicity, but many drawbacks, too:

- It lacks "High Availability." If this server goes down, your app loses availability. You could just add more servers, 
  but users tend to access one IP address only.
- Your app server is in the public subnet, making it a much easier target for hackers.
- There may be cases when you want to route requests to a service other than this app server.
- You may want "out of the box" TLS/SSL connections and/or static asset caching, both of which reduce CPU load on your
  app server.

A load balancer helps achieve all these properties:

- If a single backend service can fail, the load balancer can just route requests to a healthy one. For this reason, a 
  load balancer usually includes a health check feature to determine if a backend service can receive requests and a way 
  to register multiple backend service instances.
- A load balancer might sit in a public subnet, but backend services can reside in a private subnet, giving them 
  additional network isolation.
- A load balancer can inspect the network request it has received and make routing decisions based on its contents.
- A load balancer can terminate your TLS/SSL connection, cache static assets, and generally reduce load on your app server.
 
And there are more benefits beyond this. A load balancer can be locked down more than an app server because it doesn't 
need access to your data stores, it doesn't change very often (i.e. you don't deploy a new version of it every day like 
you do with app code), and it doesn't typically need file-system access. 

#### Does the load balancer itself need to be High Availability?

Yes! Many clients make network requests using a DNS address like `service.acme.com`. If that DNS name resolves to a 
single IP  address, then this IP address now becomes a single point of failure. 

There are typically two techniques for mitigating this. First, you can make sure that the DNS name `service.acme.com` 
resolves to two different IP addresses. Not all network clients will respond to two IP addresses in the same way, but 
most browsers will immediately try the "second" IP address if the first one fails.

Second, most networking today is [Software-Defined Networking](https://www.opennetworking.org/sdn-resources/sdn-definition),
which means that a single IP Address can be dynamically re-assigned to a server. Amazon supports this functionality 
 through the concept of an [Elastic IP Address](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html).
In fact, an Elastic IP Address can typically be re-assigned to an EC2 Instance in as little as 7 seconds, though Amazon
doesn't officially guarantee this fast a transition. 

But implementing a dynamic Elastic IP Address failover is highly non-trivial. Fortunately, Amazon's managed load 
balancers, the [Application Load Balancer](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) 
and [Classic Load Balancer](http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/introduction.html), already 
implement High Availability by including automatic failover under the hood. Amazon's managed load balancers also include
auto-scaling for when your load increases, though there are limits to how fast this can happen.

In general, you should not be configuring your own load balancer (e.g. Nginx or HAProxy) unless you can make the case 
that an existing managed load balancer solution will not meet your needs.

## Developing a module

#### Versioning

We follow the principles of [Semantic Versioning](http://semver.org/). During initial development, the major
version is to 0 (e.g., `0.x.y`), which indicates the code does not yet have a stable API. Once we hit `1.0.0`, we will
follow these rules:

1. Increment the patch version for backwards-compatible bug fixes (e.g., `v1.0.8 -> v1.0.9`).
2. Increment the minor version for new features that are backwards-compatible (e.g., `v1.0.8 -> 1.1.0`).
3. Increment the major version for any backwards-incompatible changes (e.g. `1.0.8 -> 2.0.0`).

The version is defined using Git tags.  Use GitHub to create a release, which will have the effect of adding a git tag.

#### Tests

See the [test](/test) folder for details.

## License

Please see [LICENSE.txt](/LICENSE.txt) for details on how the code in this repo is licensed.
