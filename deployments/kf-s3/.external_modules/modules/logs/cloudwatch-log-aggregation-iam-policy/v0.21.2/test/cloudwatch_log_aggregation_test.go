package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/packer"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestCloudWatchLogAggregation(t *testing.T) {

	var testcases = []struct {
		testName      string
		osName        string
		sleepDuration int
	}{
		{
			"TestCloudWatchLogAggregationUbuntu",
			"ubuntu",
			0,
		},
		{
			"TestCloudWatchLogAggregationUbuntu1804",
			"ubuntu-18",
			3,
		},
		{
			"TestCloudWatchLogAggregationAmazonLinux1",
			"amazon-linux",
			6,
		},
		{
			"TestCloudWatchLogAggregationAmazonLinux2",
			"amazon-linux-2",
			9,
		},
		{
			"TestCloudWatchLogAggregationCentOS",
			"centos",
			12,
		},
	}

	for _, testCase := range testcases {
		// The following is necessary to make sure testCase's values don't
		// get updated due to concurrency within the scope of t.Run(..) below
		testCase := testCase

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()

			// This is terrible - but attempt to stagger the test cases to
			// avoid a concurrency issue
			time.Sleep(time.Duration(testCase.sleepDuration) * time.Second)

			examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
			amiDir := fmt.Sprintf("%s/cloudwatch-log-aggregation/packer", examplesDir)
			templatePath := fmt.Sprintf("%s/%s", amiDir, "build.json")
			awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
			uniqueID := strings.ToLower(random.UniqueId())
			textToLog := fmt.Sprintf("Logged by TestCloudWatchLogAggregation %s", uniqueID)
			instanceName := fmt.Sprintf("%s-%s", testCase.testName, uniqueID)

			defer test_structure.RunTestStage(t, "teardown", func() {
				terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
				terraform.Destroy(t, terraformOptions)
			})

			test_structure.RunTestStage(t, "setup_ami", func() {
				options := &packer.Options{
					Template: templatePath,
					Only:     fmt.Sprintf("%s-build", testCase.osName),
					Vars: map[string]string{
						"aws_region":                  awsRegion,
						"module_aws_montoring_branch": getCurrentBranchName(t),
					},
				}

				amiID := packer.BuildAmi(t, options)

				terraformOptions := &terraform.Options{
					// The path to where your Terraform code is located
					TerraformDir: fmt.Sprintf("%s/cloudwatch-log-aggregation", examplesDir),
					Vars: map[string]interface{}{
						"aws_region":     awsRegion,
						"aws_account_id": aws.GetAccountId(t),
						"name":           instanceName,
						"ami":            amiID,
						"text_to_log":    textToLog,
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

			test_structure.RunTestStage(t, "validate", func() {
				checkLogsInCloudWatch(
					t,
					test_structure.LoadTerraformOptions(t, examplesDir),
					awsRegion,
					fmt.Sprintf("%s-logs", instanceName),
					textToLog,
				)
			})
		})
	}
}

// The user-data.sh script used in the cloudwatch-log-aggregation example should log the passed-in text to syslog.
// This text, in turn, should end up in CloudWatch Logs thanks to the cloudwatch-log-aggregation modules. Here, we
// verify that text is indeed available in CloudWatch Logs.
func checkLogsInCloudWatch(t *testing.T, terraformOptions *terraform.Options, awsRegion string, logGroupName string, expectedText string) {
	instanceID := terraform.Output(t, terraformOptions, "instance_id")

	if instanceID == "" {
		t.Fatalf("Instance ID was empty")
	}

	maxRetries := 10
	sleepBetweenRetries := 30 * time.Second

	for i := 0; i < maxRetries; i++ {
		logEntries, err := getCloudWatchLogEntries(t, instanceID, awsRegion, logGroupName)
		if err == nil && IsExpectedTextInLogEntries(logEntries, expectedText) {
			logger.Logf(t, "Found expected text '%s' in log entries", expectedText)
			return
		}

		if err != nil {
			logger.Logf(t, "Failed to get CloudWatch log entries for instance %s due to error: %s\n. Will try again in %s.", instanceID, err.Error(), sleepBetweenRetries)
		} else {
			logger.Logf(t, "Did not find expected text '%s' in log entries. Will try again in %s.", expectedText, sleepBetweenRetries)
		}

		time.Sleep(sleepBetweenRetries)
	}

	t.Fatalf("Still could not find expected text '%s' in log entries after %d retries.", expectedText, maxRetries)
}

// The run-cloudwatch-logs-agent.sh script configures the CloudWatch Logs Agent with the following log group and log
// stream names:
//
// log_group_name  = ${name}-logs (set by the cloudwatch-log-aggregation example User Data script)
// log_stream_name = ${instance_id}-syslog
func getCloudWatchLogEntries(t *testing.T, instanceID string, awsRegion string, logGroupName string) ([]string, error) {
	logStreamName := fmt.Sprintf("%s-syslog", instanceID)

	logger.Logf(t, "Fetching CloudWatch log entries for log stream %s and log group %s", logStreamName, logGroupName)
	return aws.GetCloudWatchLogEntriesE(t, awsRegion, logStreamName, logGroupName)
}

func IsExpectedTextInLogEntries(logEntries []string, expectedText string) bool {
	for _, logEntry := range logEntries {
		if strings.Contains(logEntry, expectedText) {
			return true
		}
	}

	return false
}
