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

func TestElastiCacheAlarms(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
		uniqueID := strings.ToLower(random.UniqueId())
		vpc := aws.GetDefaultVpc(t, awsRegion)

		terraformOptions := &terraform.Options{
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
			RetryableTerraformErrors: retryableTerraformErrors,
			MaxRetries:               maxTerraformRetries,
			TimeBetweenRetries:       sleepBetweenTerraformRetries,
		}

		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_to_aws", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.InitAndApply(t, terraformOptions)
	})

	// TODO: figure out a way to 1) make CPU and memory usage high in the ElastiCache clusters,
	// 2) subscribe to the SNS topic, and 3) check that you get notifications for the alarms.
}
