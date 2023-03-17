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
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestCloudWatchAgent(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_setup_ami", "true")
	//os.Setenv("SKIP_deploy_to_aws", "true")
	//os.Setenv("SKIP_validate_logs", "true")
	//os.Setenv("SKIP_validate_metrics", "true")
	//os.Setenv("SKIP_teardown", "true")
	//os.Setenv("SKIP_teardown_ami", "true")

	var testcases = []struct {
		testName string
		osName   string
	}{
		{
			"Ubuntu2004",
			"ubuntu-20",
		},
		{
			"Ubuntu1804",
			"ubuntu-18",
		},
		{
			"AmazonLinux1",
			"amazon-linux",
		},
		{
			"AmazonLinux2",
			"amazon-linux-2",
		},
		{
			"CentOS",
			"centos",
		},
	}

	for _, testCase := range testcases {
		// The following is necessary to make sure testCase's values don't
		// get updated due to concurrency within the scope of t.Run(..) below
		testCase := testCase

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()

			examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
			amiDir := fmt.Sprintf("%s/cloudwatch-agent/packer", examplesDir)
			templatePath := fmt.Sprintf("%s/%s", amiDir, "build.json")

			defer test_structure.RunTestStage(t, "teardown_ami", func() {
				keypair := test_structure.LoadEc2KeyPair(t, examplesDir)
				aws.DeleteEC2KeyPair(t, keypair)

				region := test_structure.LoadString(t, examplesDir, "awsRegion")
				amiId := test_structure.LoadArtifactID(t, examplesDir)
				aws.DeleteAmiAndAllSnapshots(t, region, amiId)
			})

			defer test_structure.RunTestStage(t, "teardown", func() {
				terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
				terraform.Destroy(t, terraformOptions)
			})

			test_structure.RunTestStage(t, "setup_ami", func() {
				awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
				test_structure.SaveString(t, examplesDir, "awsRegion", awsRegion)
				uniqueID := strings.ToLower(random.UniqueId())
				test_structure.SaveString(t, examplesDir, "uniqueID", uniqueID)

				// We run automated tests against this example code in many regions, and some AZs in some regions don't have certain
				// instance types. Therefore, we use this function to pick an instance type that's available in all AZs in the
				// current region.
				instanceType := aws.GetRecommendedInstanceType(t, awsRegion, []string{"t3.micro", "t2.micro"})

				options := &packer.Options{
					Template: templatePath,
					Only:     fmt.Sprintf("%s-build", testCase.osName),
					Vars: map[string]string{
						"aws_region":                  awsRegion,
						"module_aws_montoring_branch": getCurrentBranchName(t),
						"instance_type":               instanceType,
					},
				}

				amiID := packer.BuildAmi(t, options)
				test_structure.SaveArtifactID(t, examplesDir, amiID)

				keyPair := ssh.GenerateRSAKeyPair(t, 2048)
				awsKeyPair := aws.ImportEC2KeyPair(t, awsRegion, uniqueID, keyPair)
				test_structure.SaveEc2KeyPair(t, examplesDir, awsKeyPair)

				instanceName, textToLog := getNameAndTextToLog(testCase.testName, uniqueID)
				terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
					// The path to where your Terraform code is located
					TerraformDir: fmt.Sprintf("%s/cloudwatch-agent", examplesDir),
					Vars: map[string]interface{}{
						"aws_region":  awsRegion,
						"name":        instanceName,
						"ami":         amiID,
						"text_to_log": textToLog,
						"key_name":    awsKeyPair.Name,
					},
				})

				test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)
			})

			test_structure.RunTestStage(t, "deploy_to_aws", func() {
				terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
				terraform.InitAndApply(t, terraformOptions)
			})

			test_structure.RunTestStage(t, "validate_logs", func() {
				region := test_structure.LoadString(t, examplesDir, "awsRegion")
				uniqueID := test_structure.LoadString(t, examplesDir, "uniqueID")
				instanceName, textToLog := getNameAndTextToLog(testCase.testName, uniqueID)

				instanceOutputToCheck := []string{
					"instance_id_with_logs_and_metrics",
					"instance_id_no_metrics",
					"instance_id_no_cpu_metrics",
					"instance_id_no_mem_metrics",
					"instance_id_no_disk_metrics",
				}
				for _, outputName := range instanceOutputToCheck {
					checkLogsInCloudWatch(
						t,
						test_structure.LoadTerraformOptions(t, examplesDir),
						region,
						fmt.Sprintf("%s-logs", instanceName),
						textToLog,
						outputName,
					)
				}
			})

			test_structure.RunTestStage(t, "validate_metrics", func() {
				region := test_structure.LoadString(t, examplesDir, "awsRegion")

				// Testing for negation automatically is hard and time consuming, so we settle for the positive test
				// only here and assume the disable functionality works. Negation testing unfortunately should be done manually.
				instanceMetricsToCheck := []struct {
					outputName      string
					metricFunctions []func(*testing.T, string, string) ([]*cloudwatch.Metric, error)
				}{
					{
						"instance_id_with_logs_and_metrics",
						[]func(*testing.T, string, string) ([]*cloudwatch.Metric, error){getCustomMemoryMetrics, getCustomDiskMetrics, getCustomCPUMetrics},
					},
					{
						"instance_id_no_cpu_metrics",
						[]func(*testing.T, string, string) ([]*cloudwatch.Metric, error){getCustomMemoryMetrics, getCustomDiskMetrics},
					},
					{
						"instance_id_no_mem_metrics",
						[]func(*testing.T, string, string) ([]*cloudwatch.Metric, error){getCustomCPUMetrics, getCustomDiskMetrics},
					},
					{
						"instance_id_no_disk_metrics",
						[]func(*testing.T, string, string) ([]*cloudwatch.Metric, error){getCustomMemoryMetrics, getCustomCPUMetrics},
					},
				}

				for _, metricsToCheck := range instanceMetricsToCheck {
					for _, metricFunction := range metricsToCheck.metricFunctions {
						assertInstanceSendingCustomMetrics(t, test_structure.LoadTerraformOptions(t, examplesDir), region, metricsToCheck.outputName, metricFunction)
					}
				}
			})
		})
	}
}

func getNameAndTextToLog(testCaseName string, uniqueID string) (string, string) {
	instanceName := fmt.Sprintf("%s-%s", testCaseName, uniqueID)
	textToLog := fmt.Sprintf("Logged by TestCloudWatchAgent %s", uniqueID)
	return instanceName, textToLog
}

func assertInstanceSendingCustomMetrics(
	t *testing.T,
	terraformOptions *terraform.Options,
	awsRegion string,
	instanceIDOutputName string,
	metricsRetrieveFunc func(*testing.T, string, string) ([]*cloudwatch.Metric, error),
) {
	instanceID := terraform.OutputRequired(t, terraformOptions, instanceIDOutputName)

	maxRetries := 60
	sleepBetweenRetries := 15 * time.Second

	for i := 0; i < maxRetries; i++ {
		metrics, err := metricsRetrieveFunc(t, instanceID, awsRegion)

		if err != nil {
			logger.Logf(t, "Failed to get custom CloudWatch metrics for instance %s due to error: %v\n.", instanceID, err)
		} else if len(metrics) == 0 {
			logger.Logf(t, "Found 0 metrics for instance %s", instanceID)
		} else {
			logger.Logf(t, "Found custom CloudWatch metrics for instance %s: %v", instanceID, metrics)
			return
		}

		logger.Logf(t, "Will sleep for %s and try again", sleepBetweenRetries)
		time.Sleep(sleepBetweenRetries)
	}

	t.Fatalf("Could not find custom CloudWatch metrics for instance %s after %d retries.", instanceID, maxRetries)
}

func getCustomMemoryMetrics(t *testing.T, instanceID string, awsRegion string) ([]*cloudwatch.Metric, error) {
	logger.Logf(t, "Retrieving memory metrics for instance %s", instanceID)
	cloudwatchSvc := cloudwatch.New(session.New(), awsgo.NewConfig().WithRegion(awsRegion))

	input := cloudwatch.ListMetricsInput{
		Namespace:  awsgo.String("CWAgent"),
		MetricName: awsgo.String("mem_used"),
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

func getCustomDiskMetrics(t *testing.T, instanceID string, awsRegion string) ([]*cloudwatch.Metric, error) {
	logger.Logf(t, "Retrieving disk metrics for instance %s", instanceID)
	cloudwatchSvc := cloudwatch.New(session.New(), awsgo.NewConfig().WithRegion(awsRegion))

	input := cloudwatch.ListMetricsInput{
		Namespace:  awsgo.String("CWAgent"),
		MetricName: awsgo.String("diskio_read_time"),
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

func getCustomCPUMetrics(t *testing.T, instanceID string, awsRegion string) ([]*cloudwatch.Metric, error) {
	logger.Logf(t, "Retrieving CPU metrics for instance %s", instanceID)
	cloudwatchSvc := cloudwatch.New(session.New(), awsgo.NewConfig().WithRegion(awsRegion))

	input := cloudwatch.ListMetricsInput{
		Namespace:  awsgo.String("CWAgent"),
		MetricName: awsgo.String("cpu_usage_system"),
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

// The user-data.sh script used in the cloudwatch-log-aggregation example should log the passed-in text to syslog.
// This text, in turn, should end up in CloudWatch Logs thanks to the cloudwatch-log-aggregation modules. Here, we
// verify that text is indeed available in CloudWatch Logs.
func checkLogsInCloudWatch(t *testing.T, terraformOptions *terraform.Options, awsRegion string, logGroupName string, expectedText string, instanceIDOutputName string) {
	instanceID := terraform.OutputRequired(t, terraformOptions, instanceIDOutputName)

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
