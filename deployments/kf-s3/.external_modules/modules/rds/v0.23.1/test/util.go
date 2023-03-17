package test

import (
	"encoding/base64"
	"fmt"
	"os"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/service/redshift"

	awsgo "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/defaults"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/aws/aws-sdk-go/service/rds"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	terratest_testing "github.com/gruntwork-io/terratest/modules/testing"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	maxTerraformRetries          = 3
	sleepBetweenTerraformRetries = 5 * time.Second
)

var (
	// Set up terratest to retry on known failures
	retryableTerraformErrors = map[string]string{
		// Helm related terraform calls may fail when too many tests run in parallel. While the exact cause is unknown,
		// this is presumably due to all the network contention involved. Usually a retry resolves the issue.
		".*context deadline exceeded.*": "Failed to reach Tiller due to transient network error.",

		// `terraform init` frequently fails in CI due to network issues accessing plugins. The reason is unknown, but
		// eventually these succeed after a few retries.
		".*unable to verify signature.*":                    "Failed to retrieve plugin due to transient network error.",
		".*unable to verify checksum.*":                     "Failed to retrieve plugin due to transient network error.",
		".*no provider exists with the given name.*":        "Failed to retrieve plugin due to transient network error.",
		".*registry service is unreachable.*":               "Failed to retrieve plugin due to transient network error.",
		".*error creating Backup Vault Lock Configuration*": "Undetermined AWS Backup bug",
		".*A Backup vault with ARN.*does not exist.*":       "Undetermined AWS Backup bug",
	}
)

func setRetryParametersOnTerraformOptions(t *testing.T, options *terraform.Options) {
	options.RetryableTerraformErrors = retryableTerraformErrors
	options.MaxRetries = maxTerraformRetries
	options.TimeBetweenRetries = sleepBetweenTerraformRetries
}

// RDS only allows lowercase alphanumeric characters and hyphens. The name must also start with a letter.
func formatRdsName(name string) string {
	return "test" + strings.ToLower(name)
}

func deleteFinalSnapshot(t *testing.T, awsRegion string, dbInstanceName string) {
	rdsClient := aws.NewRdsClient(t, awsRegion)

	snapshotName := fmt.Sprintf("%s-final-snapshot", dbInstanceName)
	request := &rds.DeleteDBClusterSnapshotInput{DBClusterSnapshotIdentifier: awsgo.String(snapshotName)}
	_, err := rdsClient.DeleteDBClusterSnapshot(request)
	require.NoError(t, err)
}

// read the externalAccountId to use for saving RDS snapshots from the environment
func getExternalAccountId() string {
	return os.Getenv("TEST_EXTERNAL_ACCOUNT_ID")
}

func cleanupSnapshot(
	t *testing.T,
	cleanupLambdaFunctionArn string,
	dbIdentifier string,
	isAuroraDb bool,
	awsRegion string,
	snapshotSuffix string,
) {
	logger.Log(t, "Cleaning up snapshots for DB %s with suffix '%s'", dbIdentifier, snapshotSuffix)
	rdsClient := createRdsClient(t, awsRegion)
	maxRetries := 30
	sleepBetweenRetries := 10 * time.Second

	output, err := retry.DoWithRetryE(
		t,
		fmt.Sprintf("Checking if all RDS snapshots with suffix '%s' for DB %s have been deleted", snapshotSuffix, dbIdentifier),
		maxRetries,
		sleepBetweenRetries,
		func() (string, error) {
			triggerLambdaFunction(t, cleanupLambdaFunctionArn, awsRegion)

			snapshotId, err := getSnapshotId(dbIdentifier, isAuroraDb, rdsClient, snapshotSuffix)
			if err != nil {
				return "", err
			}
			if snapshotId != "" {
				return "", fmt.Errorf("A snapshot with ID %s still exists for DB %s", snapshotId, dbIdentifier)
			}
			return fmt.Sprintf("All snapshots for DB %s have been deleted!", dbIdentifier), nil
		},
	)
	logger.Log(t, output)
	require.NoError(t, err)
}

func triggerLambdaFunction(t *testing.T, lambdaFunctionArn string, region string) {
	logger.Logf(t, "Triggering lambda function %s", lambdaFunctionArn)
	lambdaClient := createLambdaClient(t, region)

	input := lambda.InvokeInput{
		FunctionName:   awsgo.String(lambdaFunctionArn),
		InvocationType: awsgo.String(lambda.InvocationTypeRequestResponse),
		LogType:        awsgo.String(lambda.LogTypeTail),
	}

	output, err := lambdaClient.Invoke(&input)
	if err != nil {
		t.Fatalf("Error invoking lambda function %s: %v", lambdaFunctionArn, err)
	}

	bytes, err := base64.StdEncoding.DecodeString(awsgo.StringValue(output.LogResult))
	if err != nil {
		t.Fatalf("Error decoding log function log result: %v", err)
	}

	logger.Logf(t, "Log result from lambda function %s: %s", lambdaFunctionArn, string(bytes))

	if awsgo.Int64Value(output.StatusCode) != int64(200) {
		t.Fatalf("Got unexpected result (%d) from calling lambda function %s.", awsgo.Int64Value(output.StatusCode), lambdaFunctionArn)
	}

	if output.FunctionError != nil {
		t.Fatalf("The lambda function %s exited with an error: %s", lambdaFunctionArn, awsgo.StringValue(output.FunctionError))
	}
}

func validateSnapshotSuffixExists(t *testing.T, dbIdentifier string, isAuroraDb bool, region string, checkShared bool, snapshotSuffix string) {
	rdsClient := createRdsClient(t, region)
	maxRetries := 120
	sleepBetweenRetries := 10 * time.Second

	output, err := retry.DoWithRetryE(t, fmt.Sprintf("Checking if an RDS snapshot for DB %s exists and has been shared", dbIdentifier), maxRetries, sleepBetweenRetries, func() (string, error) {
		snapshotId, err := getSnapshotId(dbIdentifier, isAuroraDb, rdsClient, snapshotSuffix)
		if err != nil {
			return "", err
		}
		if snapshotId == "" {
			return "", fmt.Errorf("Did not find any snapshots for DB %s", dbIdentifier)
		}
		if getExternalAccountId() == "" {
			return "No external account ID set, skipping test for cross-account sharing", nil
		}
		if checkShared {
			return validateSnapshotIsShared(t, snapshotId, isAuroraDb, rdsClient)
		} else {
			return "Found and validated snapshot", nil
		}
	})

	if err != nil {
		t.Fatalf("Failed to validate if RDS snapshot exists for DB %s: %v", dbIdentifier, err)
	}

	logger.Log(t, output)
}

func validateSnapshotExists(t *testing.T, dbIdentifier string, isAuroraDb bool, region string, checkShared bool) {
	validateSnapshotSuffixExists(t, dbIdentifier, isAuroraDb, region, checkShared, "")
}

func getSnapshotId(dbIdentifier string, isAuroraDb bool, rdsClient *rds.RDS, snapshotSuffix string) (string, error) {
	if isAuroraDb {
		// Lambda function only manages manual snapshots, so we need to make sure we only check manual snapshots here.
		input := rds.DescribeDBClusterSnapshotsInput{
			DBClusterIdentifier: awsgo.String(dbIdentifier),
			SnapshotType:        awsgo.String("manual"),
		}
		output, err := rdsClient.DescribeDBClusterSnapshots(&input)
		if err != nil {
			return "", err
		}

		for _, snapshot := range output.DBClusterSnapshots {
			snapshotStatus := awsgo.StringValue(snapshot.Status)
			snapshotId := awsgo.StringValue(snapshot.DBClusterSnapshotIdentifier)
			if strings.HasSuffix(snapshotId, snapshotSuffix) && snapshotStatus == "available" {
				return snapshotId, nil
			}
		}
		return "", nil

	} else {
		// Lambda function only manages manual snapshots, so we need to make sure we only check manual snapshots here.
		input := rds.DescribeDBSnapshotsInput{
			DBInstanceIdentifier: awsgo.String(dbIdentifier),
			SnapshotType:         awsgo.String("manual"),
		}
		output, err := rdsClient.DescribeDBSnapshots(&input)
		if err != nil {
			return "", err
		}

		for _, snapshot := range output.DBSnapshots {
			snapshotStatus := awsgo.StringValue(snapshot.Status)
			snapshotId := awsgo.StringValue(snapshot.DBSnapshotIdentifier)
			if strings.HasSuffix(snapshotId, snapshotSuffix) && snapshotStatus == "available" {
				return snapshotId, nil
			}
		}
		return "", nil
	}
}

func validateSnapshotIsShared(t *testing.T, snapshotId string, isAuroraDb bool, rdsClient *rds.RDS) (string, error) {
	if isAuroraDb {
		input := rds.DescribeDBClusterSnapshotAttributesInput{DBClusterSnapshotIdentifier: awsgo.String(snapshotId)}
		output, err := rdsClient.DescribeDBClusterSnapshotAttributes(&input)
		if err != nil {
			return "", err
		}

		logger.Logf(t, "Properties for snapshot %s: %v", snapshotId, output.DBClusterSnapshotAttributesResult.DBClusterSnapshotAttributes)
		for _, attribute := range output.DBClusterSnapshotAttributesResult.DBClusterSnapshotAttributes {
			if awsgo.StringValue(attribute.AttributeName) == "restore" && listContains(getExternalAccountId(), attribute.AttributeValues) {
				return fmt.Sprintf("Snapshot %s is properly shared with account %s!", snapshotId, getExternalAccountId()), nil
			}
		}
	} else {
		input := rds.DescribeDBSnapshotAttributesInput{DBSnapshotIdentifier: awsgo.String(snapshotId)}
		output, err := rdsClient.DescribeDBSnapshotAttributes(&input)
		if err != nil {
			return "", err
		}

		logger.Log(t, "Properties for snapshot %s: %v", snapshotId, output.DBSnapshotAttributesResult.DBSnapshotAttributes)
		for _, attribute := range output.DBSnapshotAttributesResult.DBSnapshotAttributes {
			if awsgo.StringValue(attribute.AttributeName) == "restore" && listContains(getExternalAccountId(), attribute.AttributeValues) {
				return fmt.Sprintf("Snapshot %s is properly shared with account %s!", snapshotId, getExternalAccountId()), nil
			}
		}
	}

	return "", fmt.Errorf("Snapshot %s does not seem to have been shared with account %s yet", snapshotId, getExternalAccountId())
}

func listContains(needle string, haystack []*string) bool {
	for _, str := range haystack {
		if needle == awsgo.StringValue(str) {
			return true
		}
	}

	return false
}

func getRequiredTerraformOutput(t *testing.T, terraformOptions *terraform.Options, outputName string) string {
	output, err := terraform.OutputE(t, terraformOptions, outputName)
	if err != nil {
		t.Fatal(err)
	}
	return output
}

func deploy(t *testing.T, terraformOptions *terraform.Options) {
	_, err := terraform.InitAndApplyE(t, terraformOptions)
	if err != nil {
		t.Fatalf("Error calling terraform apply: %v", err)
	}
}

func createLambdaClient(t *testing.T, awsRegion string) *lambda.Lambda {
	awsConfig := createAwsConfig(t, awsRegion)
	return lambda.New(session.New(), awsConfig)
}

func createRdsClient(t *testing.T, awsRegion string) *rds.RDS {
	awsConfig := createAwsConfig(t, awsRegion)
	return rds.New(session.New(), awsConfig)
}

func createAwsConfig(t *testing.T, awsRegion string) *awsgo.Config {
	config := defaults.Get().Config.WithRegion(awsRegion)

	_, err := config.Credentials.Get()
	if err != nil {
		t.Fatalf("Error finding AWS credentials (did you set the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables?). Underlying error: %v", err)
	}

	return config
}

// check for the perpetual diff issue, where lambda zip constantly changes and thus there is always a terraform plan
// change despite there being nothing to do.
func checkForPerpetualDiff(t *testing.T, terraformOptions *terraform.Options) {
	exitCode := terraform.PlanExitCode(t, terraformOptions)
	assert.Equal(t, exitCode, 0)
}

func createTestDbSubnetGroup(t *testing.T, region string, name string) {
	// Here we create a db subnet group for use in testing when it is provided externally. The subnet group will use the
	// first two subnets from the default VPC when it is sorted lexicographically.
	defaultVpc := aws.GetDefaultVpc(t, region)
	subnetIds := []string{}
	for _, subnet := range defaultVpc.Subnets {
		subnetIds = append(subnetIds, subnet.Id)
	}
	sort.Strings(subnetIds)

	// Now create the db subnet group
	clt := aws.NewRdsClient(t, region)
	input := &rds.CreateDBSubnetGroupInput{
		DBSubnetGroupName:        awsgo.String(name),
		DBSubnetGroupDescription: awsgo.String(fmt.Sprintf("Test DB subnet for %s", t.Name())),
		SubnetIds:                awsgo.StringSlice(subnetIds[:2]),
	}
	_, err := clt.CreateDBSubnetGroup(input)
	require.NoError(t, err)

	// Wait 30 seconds after creation to account for eventual consistency issues
	time.Sleep(30 * time.Second)
}

func deleteTestDbSubnetGroup(t *testing.T, region string, name string) {
	clt := aws.NewRdsClient(t, region)
	input := &rds.DeleteDBSubnetGroupInput{
		DBSubnetGroupName: awsgo.String(name),
	}
	_, err := clt.DeleteDBSubnetGroup(input)
	require.NoError(t, err)
}

func createTestRedshiftSubnetGroup(t *testing.T, region string, name string) {
	// Here we create a db subnet group for use in testing when it is provided externally. The subnet group will use the
	// first two subnets from the default VPC when it is sorted lexicographically.
	defaultVpc := aws.GetDefaultVpc(t, region)
	subnetIds := []string{}
	for _, subnet := range defaultVpc.Subnets {
		subnetIds = append(subnetIds, subnet.Id)
	}
	sort.Strings(subnetIds)

	// Now create the db subnet group
	clt := newRedshiftClient(t, region)
	input := &redshift.CreateClusterSubnetGroupInput{
		ClusterSubnetGroupName: awsgo.String(name),
		Description:            awsgo.String(fmt.Sprintf("Test DB subnet for %s", t.Name())),
		SubnetIds:              awsgo.StringSlice(subnetIds[:2]),
	}
	_, err := clt.CreateClusterSubnetGroup(input)
	require.NoError(t, err)

	// Wait 30 seconds after creation to account for eventual consistency issues
	time.Sleep(30 * time.Second)
}

func deleteTestRedshiftSubnetGroup(t *testing.T, region string, name string) {
	clt := newRedshiftClient(t, region)
	input := &redshift.DeleteClusterSubnetGroupInput{
		ClusterSubnetGroupName: awsgo.String(name),
	}
	_, err := clt.DeleteClusterSubnetGroup(input)
	require.NoError(t, err)
}

// NewRedshiftClient creates a Redshift client.
func newRedshiftClient(t terratest_testing.TestingT, region string) *redshift.Redshift {
	client, err := newRedshiftClientE(t, region)
	if err != nil {
		t.Fatal(err)
	}
	return client
}

// NewRedshiftClientE creates a Redshift client.
func newRedshiftClientE(t terratest_testing.TestingT, region string) (*redshift.Redshift, error) {
	sess, err := aws.NewAuthenticatedSession(region)
	if err != nil {
		return nil, err
	}

	return redshift.New(sess), nil
}
