package test

import (
	"encoding/base64"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/defaults"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/aws/aws-sdk-go/service/rds"
	"github.com/stretchr/testify/assert"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// For simplicity, we're just hard coding this to the ID of Jim's personal AWS account for now.
const TEST_EXTERNAL_ACCOUNT_ID = "168852252849"

// This test does the following:
//
// 1. Deploy the lambda-rds-snapshot example
// 2. Trigger the lambda-create-snapshot functions to create snapshots of the MySQL and Aurora DBs
// 3. This should automatically trigger the lambda-share-snapshot function too
// 4. Validate that the snapshots get created with the proper settings
// 5. Trigger the lambda-cleanup-snapshots functions to cleanup the snapshots
// 6. Validate that the snapshots have been deleted
func TestLambdaRdsSnapshot(t *testing.T) {
	t.Parallel()

	uniqueId := random.UniqueId()
	region := getAuroraRegion(t)
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/lambda-rds-snapshot",
		Vars: map[string]interface{}{
			"aws_region":          region,
			"name":                formatRdsName(uniqueId),
			"master_username":     "username",
			"master_password":     "password",
			"external_account_id": TEST_EXTERNAL_ACCOUNT_ID,

			// Set to a long time so the lambda function never runs automatically during this test. Instead,
			// we'll trigger it manually.
			"schedule_expression": "rate(5 hours)",

			// This is used to clean up all snapshots at the end of the test... Which is also how we'll verify that
			// the lambda-cleanup-snapshots module works correctly
			"max_snapshots":    0,
			"allow_delete_all": true,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	logger.Log(t, "Deploying terraform code in %s", terraformOptions.TerraformDir)
	deploy(t, terraformOptions)

	mySqlCreateSnapshotLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "mysql_create_snapshot_lambda_arn")
	mySqlCleanupSnapshotsLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "mysql_cleanup_snapshots_lambda_arn")
	mySqlDbIdentifier := getRequiredTerraformOutput(t, terraformOptions, "mysql_primary_id")

	auroraCreateSnapshotLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "aurora_create_snapshot_lambda_arn")
	auroraCleanupSnapshotsLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "aurora_cleanup_snapshots_lambda_arn")
	auroraDbIdentifier := getRequiredTerraformOutput(t, terraformOptions, "aurora_cluster_id")

	triggerLambdaFunction(t, mySqlCreateSnapshotLambdaArn, region)
	defer cleanupSnapshot(t, mySqlCleanupSnapshotsLambdaArn, mySqlDbIdentifier, false, region)

	triggerLambdaFunction(t, auroraCreateSnapshotLambdaArn, region)
	defer cleanupSnapshot(t, auroraCleanupSnapshotsLambdaArn, auroraDbIdentifier, true, region)

	validateSnapshotExists(t, mySqlDbIdentifier, false, region)
	validateSnapshotExists(t, auroraDbIdentifier, true, region)

	checkForPerpetualDiff(t, terraformOptions)

	// TODO: add a test for lambda-copy-shared-snapshot module; to do that, we'll need some external AWS account to
	// share a snapshot with this account
}

func cleanupSnapshot(t *testing.T, cleanupLambdaFunctionArn string, dbIdentifier string, isAuroraDb bool, awsRegion string) {
	logger.Log(t, "Cleaning up snapshots for DB %s", dbIdentifier)
	rdsClient := createRdsClient(t, awsRegion)
	maxRetries := 30
	sleepBetweenRetries := 10 * time.Second

	output, err := retry.DoWithRetryE(t, fmt.Sprintf("Checking if all RDS snapshots for DB %s have been deleted", dbIdentifier), maxRetries, sleepBetweenRetries, func() (string, error) {
		triggerLambdaFunction(t, cleanupLambdaFunctionArn, awsRegion)

		snapshotId, err := getSnapshotId(dbIdentifier, isAuroraDb, rdsClient)
		if err != nil {
			return "", err
		}
		if snapshotId != "" {
			return "", fmt.Errorf("A snapshot with ID %s still exists for DB %s", snapshotId, dbIdentifier)
		}
		return fmt.Sprintf("All snapshots for DB %s have been deleted!", dbIdentifier), nil
	})

	if err != nil {
		t.Fatalf("Failed to delete all snapshots for DB %s: %v", dbIdentifier, err)
	}

	logger.Log(t, output)
}

func triggerLambdaFunction(t *testing.T, lambdaFunctionArn string, region string) {
	logger.Log(t, "Triggering lambda function %s", lambdaFunctionArn)
	lambdaClient := createLambdaClient(t, region)

	input := lambda.InvokeInput{
		FunctionName:   aws.String(lambdaFunctionArn),
		InvocationType: aws.String(lambda.InvocationTypeRequestResponse),
		LogType:        aws.String(lambda.LogTypeTail),
	}

	output, err := lambdaClient.Invoke(&input)
	if err != nil {
		t.Fatalf("Error invoking lambda function %s: %v", lambdaFunctionArn, err)
	}

	bytes, err := base64.StdEncoding.DecodeString(aws.StringValue(output.LogResult))
	if err != nil {
		t.Fatalf("Error decoding log function log result: %v", err)
	}

	logger.Log(t, "Log result from lambda function %s: %s", lambdaFunctionArn, string(bytes))

	if aws.Int64Value(output.StatusCode) != int64(200) {
		t.Fatalf("Got unexpected result (%d) from calling lambda function %s.", aws.Int64Value(output.StatusCode), lambdaFunctionArn)
	}

	if output.FunctionError != nil {
		t.Fatalf("The lambda function %s exited with an error: %s", lambdaFunctionArn, aws.StringValue(output.FunctionError))
	}
}

func validateSnapshotExists(t *testing.T, dbIdentifier string, isAuroraDb bool, region string) {
	rdsClient := createRdsClient(t, region)
	maxRetries := 60
	sleepBetweenRetries := 10 * time.Second

	output, err := retry.DoWithRetryE(t, fmt.Sprintf("Checking if an RDS snapshot for DB %s exists and has been shared", dbIdentifier), maxRetries, sleepBetweenRetries, func() (string, error) {
		snapshotId, err := getSnapshotId(dbIdentifier, isAuroraDb, rdsClient)
		if err != nil {
			return "", err
		}
		if snapshotId == "" {
			return "", fmt.Errorf("Did not find any snapshots for DB %s", dbIdentifier)
		}
		return validateSnapshotIsShared(t, snapshotId, isAuroraDb, rdsClient)
	})

	if err != nil {
		t.Fatalf("Failed to validate if RDS snapshot exists for DB %s: %v", dbIdentifier, err)
	}

	logger.Log(t, output)
}

func getSnapshotId(dbIdentifier string, isAuroraDb bool, rdsClient *rds.RDS) (string, error) {
	if isAuroraDb {
		input := rds.DescribeDBClusterSnapshotsInput{DBClusterIdentifier: aws.String(dbIdentifier)}
		output, err := rdsClient.DescribeDBClusterSnapshots(&input)
		if err != nil {
			return "", err
		}
		if len(output.DBClusterSnapshots) == 0 {
			return "", nil
		}

		return aws.StringValue(output.DBClusterSnapshots[0].DBClusterSnapshotIdentifier), nil

	} else {
		input := rds.DescribeDBSnapshotsInput{DBInstanceIdentifier: aws.String(dbIdentifier)}
		output, err := rdsClient.DescribeDBSnapshots(&input)
		if err != nil {
			return "", err
		}
		if len(output.DBSnapshots) == 0 {
			return "", nil
		}

		return aws.StringValue(output.DBSnapshots[0].DBSnapshotIdentifier), nil
	}
}

func validateSnapshotIsShared(t *testing.T, snapshotId string, isAuroraDb bool, rdsClient *rds.RDS) (string, error) {
	if isAuroraDb {
		input := rds.DescribeDBClusterSnapshotAttributesInput{DBClusterSnapshotIdentifier: aws.String(snapshotId)}
		output, err := rdsClient.DescribeDBClusterSnapshotAttributes(&input)
		if err != nil {
			return "", err
		}

		logger.Logf(t, "Properties for snapshot %s: %v", snapshotId, output.DBClusterSnapshotAttributesResult.DBClusterSnapshotAttributes)
		for _, attribute := range output.DBClusterSnapshotAttributesResult.DBClusterSnapshotAttributes {
			if aws.StringValue(attribute.AttributeName) == "restore" && listContains(TEST_EXTERNAL_ACCOUNT_ID, attribute.AttributeValues) {
				return fmt.Sprintf("Snapshot %s is properly shared with account %s!", snapshotId, TEST_EXTERNAL_ACCOUNT_ID), nil
			}
		}
	} else {
		input := rds.DescribeDBSnapshotAttributesInput{DBSnapshotIdentifier: aws.String(snapshotId)}
		output, err := rdsClient.DescribeDBSnapshotAttributes(&input)
		if err != nil {
			return "", err
		}

		logger.Log(t, "Properties for snapshot %s: %v", snapshotId, output.DBSnapshotAttributesResult.DBSnapshotAttributes)
		for _, attribute := range output.DBSnapshotAttributesResult.DBSnapshotAttributes {
			if aws.StringValue(attribute.AttributeName) == "restore" && listContains(TEST_EXTERNAL_ACCOUNT_ID, attribute.AttributeValues) {
				return fmt.Sprintf("Snapshot %s is properly shared with account %s!", snapshotId, TEST_EXTERNAL_ACCOUNT_ID), nil
			}
		}
	}

	return "", fmt.Errorf("Snapshot %s does not seem to have been shared with account %s yet", snapshotId, TEST_EXTERNAL_ACCOUNT_ID)
}

func listContains(needle string, haystack []*string) bool {
	for _, str := range haystack {
		if needle == aws.StringValue(str) {
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

func createAwsConfig(t *testing.T, awsRegion string) *aws.Config {
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
