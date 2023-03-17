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

// The Elastisearch examples run with t2.small.elastic node types, which is not available in all regions. There doesn't
// seem to be an API to dynamically figure out which regions have which node types, so here, we have an incomplete,
// hand-maintained list of regions that don't have t2.small.elasticsearch nodes. Last updated July 29th, 2021.
var regionsWithoutT2SmallNodes = []string{
	"af-south-1",
	"ap-east-1",
	"ap-northeast-3",
	"eu-north-1",
	"eu-south-1",
	"me-south-1",
}

// TODO: figure out a way to 1) make CPU and memory usage high in the Elastisearch cluster,
// 2) subscribe to the SNS topic, and 3) check that you get notifications for the alarms.
func TestElasticsearchAlarms(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomStableRegion(t, []string{}, regionsWithoutT2SmallNodes)
		uniqueID := strings.ToLower(random.UniqueId())

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: fmt.Sprintf("%s/elasticsearch-alarms", examplesDir),
			Vars: map[string]interface{}{
				"aws_region":     awsRegion,
				"aws_account_id": aws.GetAccountId(t),
				"cluster_name":   "elasticsearch-" + uniqueID,
			},
		})

		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_to_aws", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.InitAndApply(t, terraformOptions)
	})
}
