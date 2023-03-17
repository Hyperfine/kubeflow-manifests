package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	awsgo "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatch"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/packer"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestCloudWatchCustomMetrics(t *testing.T) {
	var testcases = []struct {
		testName      string
		osName        string
		sleepDuration int
	}{
		{
			"TestCloudWatchCustomMetricsUbuntu",
			"ubuntu",
			0,
		},
		{
			"TestCloudWatchCustomMetricsUbuntu1804",
			"ubuntu-18",
			3,
		},
		{
			"TestCloudWatchCustomMetricsAmazonLinux",
			"amazon-linux",
			6,
		},
		{
			"TestCloudWatchCustomMetricsCentOS",
			"centos",
			9,
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

			examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")
			amiDir := fmt.Sprintf("%s/cloudwatch-custom-metrics/packer", examplesDir)
			templatePath := fmt.Sprintf("%s/%s", amiDir, "build.json")
			awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})

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
				uniqueID := strings.ToLower(random.UniqueId())
				instanceName := fmt.Sprintf("%s-%s", testCase.testName, uniqueID)

				terraformOptions := &terraform.Options{
					// The path to where your Terraform code is located
					TerraformDir: fmt.Sprintf("%s/cloudwatch-custom-metrics", examplesDir),
					Vars: map[string]interface{}{
						"aws_region":     awsRegion,
						"aws_account_id": aws.GetAccountId(t),
						"name":           instanceName,
						"ami":            amiID,
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
				assertInstanceSendingCustomMemoryMetrics(t, test_structure.LoadTerraformOptions(t, examplesDir), awsRegion)
			})
		})
	}
}

func assertInstanceSendingCustomMemoryMetrics(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	instanceID := terraform.Output(t, terraformOptions, "instance_id")

	maxRetries := 60
	sleepBetweenRetries := 15 * time.Second

	for i := 0; i < maxRetries; i++ {
		metrics, err := getCustomMemoryMetrics(instanceID, awsRegion)

		if err != nil {
			logger.Logf(t, "Failed to get custom CloudWatch memory metrics for instance %s due to error: %v\n.", instanceID, err)
		} else if len(metrics) == 0 {
			logger.Logf(t, "Found 0 metrics for instance %s", instanceID)
		} else {
			logger.Logf(t, "Found custom CloudWatch memory metrics for instance %s: %v", instanceID, metrics)
			return
		}

		logger.Logf(t, "Will sleep for %s and try again", sleepBetweenRetries)
		time.Sleep(sleepBetweenRetries)
	}

	t.Fatalf("Could not find custom CloudWatch memory metrics for instance %s after %d retries.", instanceID, maxRetries)
}

func getCustomMemoryMetrics(instanceID string, awsRegion string) ([]*cloudwatch.Metric, error) {
	cloudwatchSvc := cloudwatch.New(session.New(), awsgo.NewConfig().WithRegion(awsRegion))

	input := cloudwatch.ListMetricsInput{
		Namespace:  awsgo.String("System/Linux"),
		MetricName: awsgo.String("MemoryUtilization"),
		Dimensions: []*cloudwatch.DimensionFilter{
			{
				Name:  awsgo.String("InstanceId"),
				Value: awsgo.String(instanceID),
			},
		},
	}

	out, err := cloudwatchSvc.ListMetrics(&input)
	if err != nil {
		return nil, err
	}

	return out.Metrics, err
}
