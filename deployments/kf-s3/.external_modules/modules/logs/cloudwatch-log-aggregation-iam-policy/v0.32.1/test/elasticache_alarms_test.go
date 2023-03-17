package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

// The ElastiCache examples run with cache.t2.micro node types, which is not available in all regions. There doesn't
// seem to be an API to dynamically figure out which regions have which node types, so here, we have an incomplete,
// hand-maintained list of regions that have cache.t2.micro nodes. Last updated July 9th, 2021.
var regionsWithT2MicroNodes = []string{
	"us-east-1",
	"us-east-2",
	"us-west-1",
	"us-central-1",
	"us-west-1",
}

// TODO: figure out a way to 1) make CPU and memory usage high in the ElastiCache clusters,
// 2) subscribe to the SNS topic, and 3) check that you get notifications for the alarms.
func TestElastiCacheAlarms(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomStableRegion(t, regionsWithT2MicroNodes, []string{})
		uniqueID := strings.ToLower(random.UniqueId())
		vpc := aws.GetDefaultVpc(t, awsRegion)

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: fmt.Sprintf("%s/elasticache-alarms", examplesDir),
			Vars: map[string]interface{}{
				"aws_region":             awsRegion,
				"aws_account_id":         aws.GetAccountId(t),
				"vpc_id":                 vpc.Id,
				"subnet_ids":             getSubnetIds(*vpc),
				"redis_cluster_name":     "redis-" + uniqueID,
				"memcached_cluster_name": "memcached-" + uniqueID,
			},
		})

		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_to_aws", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.InitAndApply(t, terraformOptions)
	})
}

func TestElastiCacheAlarmsAllEnabled(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomStableRegion(t, regionsWithT2MicroNodes, []string{})
		uniqueID := strings.ToLower(random.UniqueId())
		vpc := aws.GetDefaultVpc(t, awsRegion)

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: fmt.Sprintf("%s/elasticache-alarms", examplesDir),
			Vars: map[string]interface{}{
				"aws_region":             awsRegion,
				"aws_account_id":         aws.GetAccountId(t),
				"vpc_id":                 vpc.Id,
				"subnet_ids":             getSubnetIds(*vpc),
				"redis_cluster_name":     "redis-" + uniqueID,
				"memcached_cluster_name": "memcached-" + uniqueID,
				"redis_monitor_database_memory_usage_percentage": true,
				"redis_monitor_curr_connections":                 true,
				"redis_monitor_replication_lag":                  true,
			},
		})

		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_to_aws", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.InitAndApply(t, terraformOptions)
	})
}
