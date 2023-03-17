package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cloudwatch"
	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
	taws "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

const TestFilterPattern = "TestFilterPattern"

func TestCloudwatchLogsMetricFilter(t *testing.T) {
	t.Parallel()
	awsRegion := taws.GetRandomStableRegion(t, []string{}, []string{})
	uniqueId := random.UniqueId()

	// Create a CloudWatch Logs group to apply the metric filter to
	logGroupName := "MetricFilterTest-" + uniqueId
	defer deleteCloudwatchLogsGroup(t, awsRegion, logGroupName)
	createCloudwatchLogsGroup(t, awsRegion, logGroupName)

	// Set up the metric filter
	exampleDir := "../examples/cloudwatch-logs-metric-filters"
	names := []string{"MetricFilterAlarm-" + uniqueId}
	terraformOptions := getMetricFilterTerraformOptions(t, names, exampleDir, awsRegion, logGroupName, uniqueId)

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Create a message that will match the filter
	putLogMessage(t, awsRegion, logGroupName)

	// Ensure the alarm status enters error state when the filter matches the message we just sent
	checkAlarmFunc := func() (string, error) {
		client := newCloudWatchClient(t, awsRegion)
		input := &cloudwatch.DescribeAlarmsInput{
			AlarmNames: []*string{aws.String(names[0])},
			StateValue: aws.String(cloudwatch.StateValueAlarm),
		}
		output, err := client.DescribeAlarms(input)
		if err != nil {
			return "", err
		}
		if len(output.MetricAlarms) != 1 {
			return "", fmt.Errorf("No alarms named %s with state %s found", names[0], cloudwatch.StateValueAlarm)
		}
		return aws.StringValue(output.MetricAlarms[0].StateReason), nil
	}

	checkAlarmDesc := "Check status of CloudWatch metric alarm " + names[0]
	// Wait up to 5.5 minutes for the alarm state
	_, err := doWithRetryAndTimeout(t, checkAlarmFunc, checkAlarmDesc, 11, 30*time.Second, 10*time.Second)
	require.Nil(t, err)
}

func newCloudWatchClient(t *testing.T, awsRegion string) *cloudwatch.CloudWatch {
	sess, err := taws.NewAuthenticatedSession(awsRegion)
	require.Nil(t, err)
	return cloudwatch.New(sess)
}

func deleteCloudwatchLogsGroup(t *testing.T, awsRegion, logGroupName string) {
	client := taws.NewCloudWatchLogsClient(t, awsRegion)
	deleteLogGroupInput := &cloudwatchlogs.DeleteLogGroupInput{
		LogGroupName: aws.String(logGroupName),
	}
	_, err := client.DeleteLogGroup(deleteLogGroupInput)
	require.Nil(t, err)
}

func createCloudwatchLogsGroup(t *testing.T, awsRegion, logGroupName string) {
	client := taws.NewCloudWatchLogsClient(t, awsRegion)
	createLogGroupInput := &cloudwatchlogs.CreateLogGroupInput{
		LogGroupName: aws.String(logGroupName),
	}
	_, err := client.CreateLogGroup(createLogGroupInput)
	require.Nil(t, err)

	createLogStreamInput := &cloudwatchlogs.CreateLogStreamInput{
		LogGroupName:  aws.String(logGroupName),
		LogStreamName: aws.String(logGroupName),
	}
	_, err = client.CreateLogStream(createLogStreamInput)
	require.Nil(t, err)
}

func putLogMessage(t *testing.T, awsRegion, logGroupName string) {
	client := taws.NewCloudWatchLogsClient(t, awsRegion)
	ts := aws.TimeUnixMilli(time.Now())
	inputLogEvent := cloudwatchlogs.InputLogEvent{
		Message:   aws.String(TestFilterPattern),
		Timestamp: aws.Int64(ts),
	}
	putLogEventsInput := &cloudwatchlogs.PutLogEventsInput{
		LogGroupName:  aws.String(logGroupName),
		LogStreamName: aws.String(logGroupName),
		LogEvents:     []*cloudwatchlogs.InputLogEvent{&inputLogEvent},
	}
	_, err := client.PutLogEvents(putLogEventsInput)
	require.Nil(t, err)
}

type metric struct {
	pattern     string
	description string
}

func getMetricFilterTerraformOptions(t *testing.T, names []string, terraformDir, awsRegion, logGroupName, uniqueId string) *terraform.Options {
	var metricMap = make(map[string]map[string]string)
	for _, name := range names {
		metricMap[name] = map[string]string{
			"pattern":     TestFilterPattern,
			"description": "Test Description",
		}
	}
	return &terraform.Options{
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"aws_region":                 awsRegion,
			"metric_map":                 metricMap,
			"cloudwatch_logs_group_name": logGroupName,
			"metric_namespace":           "MetricFilterTest-" + uniqueId,
			"alarm_comparison_operator":  "GreaterThanOrEqualToThreshold",
			"alarm_evaluation_periods":   "1",
			"alarm_period":               "300",
			"alarm_statistic":            "Sum",
			"alarm_threshold":            "1",
			"alarm_treat_missing_data":   "notBreaching",
			"sns_topic_name":             "TestingTopic-" + uniqueId,
		},
		RetryableTerraformErrors: retryableTerraformErrors,
		MaxRetries:               maxTerraformRetries,
		TimeBetweenRetries:       sleepBetweenTerraformRetries,
	}
}
