package test

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
)

const KEY_REGION = "region"
const KEY_SQS_QUEUE_NAME = "queue"
const KEY_SNS_TOPIC_NAME = "topic"
const KEY_KINESIS_STREAM_NAME = "stream"

const OUTPUT_SQS_DLQUEUE = "dead_letter_queue_url"
const OUTPUT_SQS_QUEUE = "queue_url"

const OUTPUT_KINESIS_RETENTION = "retention_period"
const OUTPUT_KINESIS_ENC_TYPE = "encryption_type"
const OUTPUT_KINESIS_SHARD_COUNT = "shard_count"

// As of 2018-12-20, these AWS regions do not support the SQS FIFO Queues.
var REGIONS_WITHOUT_FIFO_QUEUES = []string{
	"ap-south-1",
	"ap-southeast-1",
	"ap-northeast-2",
	"ca-central-1",
	"eu-central-1",
	"eu-west-2",
	"sa-east-1",
	"us-west-1",
}

func createTerratestOptionsForSQS(exampleDir string, region string, queueName string) *terraform.Options {
	terratestOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: exampleDir,
		Vars: map[string]interface{}{
			"aws_region": region,
			"name":       queueName,
		},
	}
	return terratestOptions
}

func createTerratestOptionsForSNS(exampleDir string, region string, topicName string, allowPub []string, allowSub []string) *terraform.Options {
	terratestOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: exampleDir,
		Vars: map[string]interface{}{
			"aws_region":               region,
			"name":                     topicName,
			"allow_publish_accounts":   allowPub,
			"allow_subscribe_accounts": allowSub,
		},
	}
	return terratestOptions
}

func createTerratestOptionsForKinesis(exampleDir string, region string, streamName string, numShards int, encType string, avgDataSize int, recPerSec int, numConsumers int, retentionPeriod int) *terraform.Options {
	terratestOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: exampleDir,
		Vars: map[string]interface{}{
			"aws_region":              region,
			"name":                    streamName,
			"average_data_size_in_kb": avgDataSize,
			"records_per_second":      recPerSec,
			"number_of_consumers":     numConsumers,
			"retention_period":        retentionPeriod,
			"encryption_type":         encType,
		},
	}
	if numShards >= 0 {
		terratestOptions.Vars["number_of_shards"] = numShards
	}
	return terratestOptions
}
