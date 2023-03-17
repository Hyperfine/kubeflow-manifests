# ELB & ALB Access Logs Module

This module creates an [S3 bucket](https://aws.amazon.com/s3/) that can be used to store [Elastic Load Balancer (ELB)
Access Logs](http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/access-log-collection.html) or 
[Application Load Balancer Access Logs](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html). 

These logs capture detailed information about all requests handled by your load balancer. Each log contains information 
such as the time the request was received, the client's IP address, latencies, request paths, and server responses. You 
can use these access logs to analyze traffic patterns and to troubleshoot issues.

## Example

See the [load-balancer-access-logs examples](/examples/load-balancer-access-logs) for an example of how to use this 
module with an ELB or ALB.

## How do you use this module?

First, add a `module` resource to your Terraform templates that points to this load-balancer-access-logs module:

```hcl
module "load_balancer_access_logs_bucket" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/load-balancer-access-logs?ref=v0.0.28"

  aws_account_id = "1234567"
  aws_region = "us-east-1"
  s3_bucket_name = "a-unique-name-for-my-access-logs-s3-bucket"
  s3_logging_prefix = "my-app"
}
```

Important notes:

* All S3 bucket names, including `s3_bucket_name`, must be *globally* unique across all AWS customers. 
* If you're using an ELB/ALB, the `s3_logging_prefix` must match the name of the ELB/ALB in order for it to have access to the right S3 object. 

Next, just add an `access_logs` block to your `aws_elb` or `aws_alb` definition:

```hcl
# If using ELB...
resource "aws_elb" "load_balancer_stg" {
  name = "my-elb"

  access_logs {
    bucket = "${module.elb_access_logs_bucket.s3_bucket_name}"
    interval = 5
    bucket_prefix = "my-app"
  }
  
  depends_on = ["module.alb_access_logs_bucket"]
}

# If using ALB...
resource "aws_alb" "example" {
  name = "${var.name}"
  subnets = ["${var.subnet_ids}"]

  access_logs {
    bucket = "${module.alb_access_logs_bucket.s3_bucket_name}"
    prefix = "${var.name}"
    enabled = true
  }
  
  depends_on = ["module.alb_access_logs_bucket"]
}
```

That's it! Apply these templates and in a few minutes, you should start seeing access logs in that S3 bucket.

## Upgrading From the `elb-access-logs` Module

See the [Upgrade Guide](_docs/Upgrade Guide.md) for details on upgrading the now-deprecated `elb-access-logs` module to 
the new `load-balancer-access-logs` modules.

## Viewing and Accessing Log Files

### How do I the access log files for my ALB?

The `s3_bucket_name` output variable will give you the name of the S3 bucket where your access logs are
stored. Find this bucket in the [S3 console](https://console.aws.amazon.com/s3/home), click down through the folders
until you find your ELB or ALB's name, and inside you'll find the access logs. For details on the log format, see:

  - Classic Load Balancer: [Monitor Your Load Balancer Using Elastic Load Balancing Access Logs](http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/access-log-collection.html)
  - Application Load Balancer: [Monitor Your Load Balancer Using Elastic Load Balancing Access Logs](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html)

### How do I query and visualize the log files?

[Amazon Athena](http://docs.aws.amazon.com/athena/latest/ug/what-is.html) was announced in December 2016 as an easy way 
to query data stored in S3. You might also consider using [Amazon QuickSight](https://quicksight.aws/) to visualize this 
data.

## Known Issues

- If you attempt to enable or disable archiving of log files, Terraform will attempt to delete and re-create your existing S3
  Bucket. This will fail because your Bucket won't be empty, but more importantly, the goal here is just to change some S3
  Lifecycle Rules, so a destroy/re-create is unnecessary.
  
  Here's what the `terraform plan` output looks like if you attempt to disable archiving:
  
  ```
  - module.access_logs.aws_s3_bucket.access_logs_with_logs_archived
  
  + module.access_logs.aws_s3_bucket.access_logs_with_logs_not_archived
      acceleration_status:                                                 "<computed>"
      acl:                                                                 "private"
      arn:                                                                 "<computed>"
      ...
  ```
  
  Fortunately, there's a 1-line workaround using Terraform's built-in state management features:
  
  **If you are ENABLING archiving:** `terraform state mv module.access_logs.aws_s3_bucket.access_logs_with_logs_archived module.access_logs.aws_s3_bucket.access_logs_with_logs_not_archived`
  
  **If you are DISABLING archiving:** `terraform state mv module.access_logs.aws_s3_bucket.access_logs_with_logs_not_archived module.access_logs.aws_s3_bucket.access_logs_with_logs_archived`
  
  These commands tell Terraform to update the state file, and treat the bucket that Terraform wanted to create as already 
  existing. Now you'll get a yellow "modify" output when running `terraform plan` and no destroy/re-create will be needed.
 
