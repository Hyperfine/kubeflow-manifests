# Kinesis Stream Module 


This module makes it easy to deploy a Kinesis stream

## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [vars.tf](./vars.tf) for all the variables you can set on this module.

## Shard Sizing
Kinesis streams acheive scalability by using [shards](https://en.wikipedia.org/wiki/Shard_(database_architecture)). This module allows you to either
specify `number_of_shards` directly or to specify the `average_data_size_in_kb`, `records_per_second` and
 `number_of_consumers` variables and the module will calculate the proper number of shards that should be used
  based on [AWS best practices](https://docs.aws.amazon.com/streams/latest/dev/amazon-kinesis-streams.html).
  
  `incoming_write_bandwidth_in_kb = average_data_size_in_kb * records_per_second`
  
  `outgoing_read_bandwidth_in_kb = incoming_write_bandwidth_in_kb * number_of_consumers`
  
  `number_of_shards = max(incoming_write_bandwidth_in_kb/1000, outgoing_read_bandwidth_in_kb/2000)`

## Encryption
Kinesis streams support server-side encryption as described in the
[Kinesis SSE documentation](https://docs.aws.amazon.com/streams/latest/dev/what-is-sse.html). It can be switched
on retrospectively for existing streams with no interruptions (although only new data will be encrypted).

To enable encryption, set the following parameter
 
 `encryption_type = "SSE"`
  
This will use the default AWS service key for Kinesis, `aws/kinesis`.

If you need to use a custom key, see the
[master key module](https://github.com/gruntwork-io/module-security-public/tree/master/modules/kms-master-key) as well as
[documentation on user-generated KMS master keys](https://docs.aws.amazon.com/streams/latest/dev/creating-using-sse-master-keys.html)
for further information on how to create them. You can specify one using

 `kms_key_id = "alias/<my_cmk_alias>"`

## Examples
Here are some examples of how you might deploy a Kinesis stream with this module:

```hcl-terraform
module "kinesis" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-messaging.git//modules/kinesis?ref=v0.0.1"

  name = "my-stream"
  retention_period = 48

  number_of_shards = 1
  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "IteratorAgeMilliseconds",
    "OutgoingBytes",
    "OutgoingRecords",
    "ReadProvisionedThroughputExceeded",
    "WriteProvisionedThroughputExceeded"
  ]
 
}
```

```hcl-terraform
module "kinesis" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-messaging.git//modules/kinesis?ref=v0.0.1"
  name = "my-stream"
  retention_period = 48
  
  average_data_size_in_kb = 20
  records_per_second = 10
  number_of_consumers = 10
  
  shard_level_metrics = [
      "ReadProvisionedThroughputExceeded",
      "WriteProvisionedThroughputExceeded"
    ]
}
```