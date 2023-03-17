package test

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/slack-go/slack"
	"github.com/stretchr/testify/assert"
)

const testAlarmSlackChannelID = "CMM612EHE"

// NOTE: This test requires the following two environment variables to be set. These can be obtained from the app
// settings page for the slack app "Test CloudWatch Slack".
// - GRUNTWORK_SLACK_WEBHOOK_URL_FOR_TEST
// - GRUNTWORK_SLACK_TOKEN_FOR_TEST
func TestCloudWatchToSlack(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_setup", "true")
	//os.Setenv("SKIP_deploy_to_aws", "true")
	//os.Setenv("SKIP_validate_slack", "true")
	//os.Setenv("SKIP_teardown", "true")
	//os.Setenv("SKIP_cleanup_keypair", "true")

	gruntworkSlackWebhookURLForTest := os.Getenv("GRUNTWORK_SLACK_WEBHOOK_URL_FOR_TEST")
	if gruntworkSlackWebhookURLForTest == "" {
		t.Fatalf("The GRUNTWORK_SLACK_WEBHOOK_URL_FOR_TEST environment variable must be set for this test.")
	}

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	defer test_structure.RunTestStage(t, "cleanup_keypair", func() {

		keyPair := test_structure.LoadEc2KeyPair(t, examplesDir)
		aws.DeleteEC2KeyPair(t, keyPair)
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
		uniqueID := strings.ToLower(random.UniqueId())

		keyPair := aws.CreateAndImportEC2KeyPair(t, awsRegion, uniqueID)
		test_structure.SaveEc2KeyPair(t, examplesDir, keyPair)

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: fmt.Sprintf("%s/cloudwatch-to-slack", examplesDir),
			Vars: map[string]interface{}{
				"aws_region":        awsRegion,
				"aws_account_id":    aws.GetAccountId(t),
				"name":              uniqueID,
				"keypair_name":      uniqueID,
				"slack_webhook_url": gruntworkSlackWebhookURLForTest,
			},
		})

		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_to_aws", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate_slack", func() {
		gruntworkSlackTokenForTest := os.Getenv("GRUNTWORK_SLACK_TOKEN_FOR_TEST")
		if gruntworkSlackTokenForTest == "" {
			t.Fatalf("The GRUNTWORK_SLACK_TOKEN_FOR_TEST environment variable must be set for this test.")
		}

		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		instanceID := terraform.Output(t, terraformOptions, "instance_id")
		expectedText := fmt.Sprintf("ec2-high-cpu-utilization-%s", instanceID)

		// Keep retrieving the last 50 messages, starting with 15 minutes ago
		now := time.Now()
		fifteenMinAgo := now.Add(-15 * time.Minute)

		slackClt := slack.New(gruntworkSlackTokenForTest)
		params := slack.GetConversationHistoryParameters{
			ChannelID: testAlarmSlackChannelID,
			Limit:     50,
			Oldest:    strconv.FormatInt(fifteenMinAgo.Unix(), 10),
		}

		retry.DoWithRetry(
			t,
			"verify slack message from alarm",
			// Try for up to 10 minutes, checking every 15 seconds
			40, 15*time.Second,
			func() (string, error) {
				resp, err := slackClt.GetConversationHistory(&params)
				if err != nil {
					return "", retry.FatalError{Underlying: err}
				}
				// Incoming webhooks are categorized as bot messages, with the message content being stored as an
				// attachment, so we walk the messages looking for bot posted messages and match against the attachment
				// to look for the message posted by the CloudWatch Alarm.
				for _, msg := range resp.Messages {
					if msg.SubType != slack.MsgSubTypeBotMessage {
						continue
					}
					for _, attachment := range msg.Attachments {
						if strings.Contains(attachment.Text, expectedText) {
							return "found", nil
						}
					}
				}
				return "not found", fmt.Errorf("still no alarm message")
			},
		)
	})
}

func TestCreateSnsToSlackNoResources(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
	uniqueID := strings.ToLower(random.UniqueId())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: fmt.Sprintf("%s/cloudwatch-to-slack", examplesDir),
		Vars: map[string]interface{}{
			"aws_region":        awsRegion,
			"aws_account_id":    aws.GetAccountId(t),
			"name":              uniqueID,
			"slack_webhook_url": "",
			"create_resources":  false,
		},
	})

	planOut := terraform.InitAndPlan(t, terraformOptions)
	planCounts := terraform.GetResourceCount(t, planOut)
	assert.Equal(t, planCounts.Add, 0)
	assert.Equal(t, planCounts.Change, 0)
	assert.Equal(t, planCounts.Destroy, 0)
}
