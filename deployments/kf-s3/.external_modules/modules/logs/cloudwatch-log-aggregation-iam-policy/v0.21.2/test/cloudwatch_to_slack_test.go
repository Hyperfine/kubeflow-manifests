package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// A webhook we created in the Gruntwork Slack account for testing
const GRUNTWORK_SLACK_WEBHOOK_URL_FOR_TEST = "https://hooks.slack.com/services/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"

func TestCloudWatchToSlack(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
		uniqueID := strings.ToLower(random.UniqueId())

		terraformOptions := &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: fmt.Sprintf("%s/cloudwatch-to-slack", examplesDir),
			Vars: map[string]interface{}{
				"aws_region":        awsRegion,
				"aws_account_id":    aws.GetAccountId(t),
				"name":              uniqueID,
				"slack_webhook_url": GRUNTWORK_SLACK_WEBHOOK_URL_FOR_TEST,
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

	// TODO: trigger some alarms and check that alerts show up in Slack
}

func TestCreateSnsToSlackNoResources(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
	uniqueID := strings.ToLower(random.UniqueId())

	terraformOptions := &terraform.Options{
		TerraformDir: fmt.Sprintf("%s/cloudwatch-to-slack", examplesDir),
		Vars: map[string]interface{}{
			"aws_region":        awsRegion,
			"aws_account_id":    aws.GetAccountId(t),
			"name":              uniqueID,
			"slack_webhook_url": GRUNTWORK_SLACK_WEBHOOK_URL_FOR_TEST,
			"create_resources":  false,
		},
		RetryableTerraformErrors: retryableTerraformErrors,
		MaxRetries:               maxTerraformRetries,
		TimeBetweenRetries:       sleepBetweenTerraformRetries,
	}

	planOut := terraform.InitAndPlan(t, terraformOptions)
	planCounts := terraform.GetResourceCount(t, planOut)
	assert.Equal(t, planCounts.Add, 0)
	assert.Equal(t, planCounts.Change, 0)
	assert.Equal(t, planCounts.Destroy, 0)
}
