![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.0-blue.svg)

# Data-Storage Modules

This repo contains modules for running relational databases such as MySQL, PostgreSQL, and Aurora on Amazon's
[Relational Database Service (RDS)](https://aws.amazon.com/rds/).

* [aurora](/modules/aurora): Deploy an RDS Aurora cluster.
* [rds](/modules/rds): Deploy an RDS Cluster for MySQL, Postgres, or MariaDB. 

## What is a Gruntwork Module?

At [Gruntwork](http://www.gruntwork.io), we've taken the thousands of hours we spent building infrastructure on AWS and
condensed all that experience and code into pre-built **packages** or **modules**. Each module is a battle-tested,
best-practices definition of a piece of infrastructure, such as a VPC, ECS cluster, or an Auto Scaling Group. Modules
are versioned using [Semantic Versioning](http://semver.org/) to allow Gruntwork clients to keep up to date with the
latest infrastructure best practices in a systematic way.

## How do you use a Gruntwork Module?

Most of our modules contain either:

1. [Terraform](https://www.terraform.io/) code
1. Scripts & binaries

#### Using a Terraform module

To use a module in your Terraform templates, create a `module` resource and set its `source` field to the Git URL of
this repo. You should also set the `ref` parameter so you're fixed to a specific version of this repo, as the `master`
branch may have backwards incompatible changes (see [module
sources](https://www.terraform.io/docs/modules/sources.html)).

For example, to use `v1.0.8` of one of the data-storage modules, you would add the following:

```hcl
module "postgres_prod" {
  source = "git::git@github.com:gruntwork-io/module-data-storage.git//modules/rds?ref=v1.0.8"

  // set the parameters for the rds module
}
```

*Note: the double slash (`//`) is intentional and required. It's part of Terraform's Git syntax (see [module
sources](https://www.terraform.io/docs/modules/sources.html)).*

See the module's documentation and `vars.tf` file for all the parameters you can set. Run `terraform get -update` to
pull the latest version of this module from this repo before running the standard  `terraform plan` and
`terraform apply` commands.

*NOTE: To automatically enforce terraform best practices, we recommend using [terragrunt](https://github.com/gruntwork-io/terragrunt).*

#### Using scripts & binaries

You can install the scripts and binaries in the `modules` folder of any repo using the [Gruntwork
Installer](https://github.com/gruntwork-io/gruntwork-installer). For example, if the scripts you want to install are
in the `modules/ecs-scripts` folder of the https://github.com/gruntwork-io/module-ecs repo, you could install them
as follows:

```bash
gruntwork-install --module-name "ecs-scripts" --repo "https://github.com/gruntwork-io/module-ecs" --tag "0.0.1"
```

See the docs for each script & binary for detailed instructions on how to use them.

## What is RDS?

Relational Database Service (RDS) is Amazon's implementation of a best-practices setup for the most popular databases
including PostgreSQL, MySQL, Oracle, and SQL Server. RDS automatically includes real-time failover, makes it easy to add
read replicas, automatically takes nightly snapshots, allows for easy database upgrades, and for easy machine upgrades.

You pay a small premium over running the services yourself and everything is pre-configured for you.

## Developing a module

#### Versioning

We are following the principles of [Semantic Versioning](http://semver.org/). During initial development, the major
version is to 0 (e.g., `0.x.y`), which indicates the code does not yet have a stable API. Once we hit `1.0.0`, we will
follow these rules:

1. Increment the patch version for backwards-compatible bug fixes (e.g., `v1.0.8 -> v1.0.9`).
2. Increment the minor version for new features that are backwards-compatible (e.g., `v1.0.8 -> 1.1.0`).
3. Increment the major version for any backwards-incompatible changes (e.g. `1.0.8 -> 2.0.0`).

The version is defined using Git tags. Use GitHub to create a release, which will have the effect of adding a git tag.

#### Tests

See the [test](/test) folder for details.

## License

Please see [LICENSE.txt](/LICENSE.txt) for details on how the code in this repo is licensed.
