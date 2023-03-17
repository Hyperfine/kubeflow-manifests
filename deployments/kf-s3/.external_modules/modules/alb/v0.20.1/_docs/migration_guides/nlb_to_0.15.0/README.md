# Migrating nlb to v0.15.0

If you are using the `nlb` module and would like to upgrade to `v0.15.0`, you will need to convert your usage of the
`nlb` module with direct calls to the `aws_lb` resource. At a high level, this involves two steps:

1. [Convert module call to aws_lb resource](#convert-module-call-to-aws_lb-resource)
1. [Migrate module state to new aws_lb resource](#migrate-module-state-to-new-aws_lb-resource)


## Convert module call to aws_lb resource

The first step in the migration process is to update the code so that you have an equivalent configuration of the NLB
using the `aws_lb` resource instead of the `nlb` module block. With the exception of access logs and subnet mappings,
all the variables should translate directly to an attribute on the resource. If you have trouble identifying which
attribute/subblock should be set on the `aws_lb` resource, you can always refer to [the `nlb` module implementation
code](https://github.com/gruntwork-io/module-load-balancer/tree/v0.14.2/modules/nlb) to see what it was in the module
and replicate it on your resource.

For example, consider the provided terraform code in [the `before_migration` folder](./before_migration/main.tf). This
holds an example of an `nlb` module call that uses multiple subnet mappings blocks as opposed to using the full list of
subnets provided by the VPC. Additionally, this configures the NLB to store its access logs in S3.

```
module "nlb" {
  source = "git::git@github.com:gruntwork-io/module-load-balancer.git//modules/nlb?ref=v0.14.2"

  aws_region = var.aws_region

  nlb_name         = var.nlb_name
  environment_name = var.environment_name
  is_internal_nlb  = false

  subnet_mapping = [
    {
      subnet_id     = element(tolist(data.aws_subnet_ids.default.ids), 0)
      allocation_id = aws_eip.example1.id
    },
    {
      subnet_id     = element(tolist(data.aws_subnet_ids.default.ids), 1)
      allocation_id = aws_eip.example2.id
    },
  ]

  subnet_mapping_size = 2

  enable_cross_zone_load_balancing = false
  ip_address_type                  = "ipv4"

  vpc_id                         = data.aws_vpc.default.id
  vpc_subnet_ids                 = data.aws_subnet_ids.default.ids
  enable_nlb_access_logs         = true
  nlb_access_logs_s3_bucket_name = module.nlb_access_logs_bucket.s3_bucket_name
}
```

To convert this module call to the `aws_lb` resource, refer to [the documentation for the
resource](https://www.terraform.io/docs/providers/aws/r/lb.html) and update the inputs to reflect what you had for the
module call. This should look something like what we have in [the `after_migration` folder](./after_migration/main.tf).

```
resource "aws_lb" "nlb" {
  name               = var.nlb_name
  internal           = false
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id     = element(tolist(data.aws_subnet_ids.default.ids), 0)
    allocation_id = aws_eip.example1.id
  }

  subnet_mapping {
    subnet_id     = element(tolist(data.aws_subnet_ids.default.ids), 1)
    allocation_id = aws_eip.example2.id
  }

  enable_cross_zone_load_balancing = false
  ip_address_type                  = "ipv4"

  tags = {
    Environment = "test"
  }

  access_logs {
    bucket  = module.nlb_access_logs_bucket.s3_bucket_name
    prefix  = var.nlb_name
    enabled = true
  }
}
```

Note how the `subnet_mapping` list was expanded out into blocks, and the access logs was translated to the
`access_logs` block for the resource.

## Migrate modules state to new aws_lb resource

If you are making this change on existing infrastructure, you will need to do a state migration to ensure that Terraform
doesn't attempt to recreate the NLB. To do the state migration, first identify the state id of the `aws_lb` resource
created by the module. You can do this by running `terraform state list`. You should get output similar to below:

```
data.aws_ami.ubuntu
data.aws_caller_identity.current
data.aws_subnet_ids.default
data.aws_vpc.default
data.template_file.user_data
aws_eip.example1
aws_eip.example2
aws_instance.example_server
aws_lb_listener.example_server
aws_lb_target_group.example_server
aws_lb_target_group_attachment.example_server
aws_security_group.example_server
module.nlb.data.template_file.nlb_arn
module.nlb.aws_lb.nlb_2_az[0]
module.nlb.aws_lb_target_group.blackhole
module.nlb_access_logs_bucket.data.aws_elb_service_account.main
module.nlb_access_logs_bucket.data.aws_iam_policy_document.access_logs_bucket_policy
module.nlb_access_logs_bucket.aws_s3_bucket.access_logs_with_logs_archived_only[0]
```

The state id we are interested in is the `aws_lb` resource that is namespaced to the module. In the above list (which
corresponds to the state list you will see for our example `before_migration` Terraform module), the state id we are
looking for is `module.nlb.aws_lb.nlb_2_az[0]`. We will want to move this state under the new id that corresponds to the
resource we created.

To migrate the state, we will use the `terraform state mv` command (note: if you're using Terragrunt, change all of
these commands to equivalent `terragrunt state mv` commands). The new id is the resource id. In our example, this
corresponds to `aws_lb.nlb`. Here is the state migration call:

```
terraform state mv module.nlb.aws_lb.nlb_2_az[0] aws_lb.nlb
```

You can verify you successfully moved the state by running `terraform plan`. If you correctly mapped the module inputs
to the resource, Terraform should not detect any changes to the NLB.

If you made a mistake in the above procedure, you can always revert the state by reversing the args to `state mv`. In
our example, this will be:

```
terraform state mv aws_lb.nlb module.nlb.aws_lb.nlb_2_az[0]
```

This moves the state back to what it was before so that you can revert your code back to `v0.14.2`.
