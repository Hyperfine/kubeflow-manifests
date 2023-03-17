package test

import (
	"fmt"
	"path/filepath"
	"testing"

	awsgo "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// A basic sanity check of the RDS example that just deploys and undeploys it to make sure there are no errors in
// the templates
// TODO: try to actually connect to the RDS DBs and check they are working
func TestRdsPostgres(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomRegion(t, []string{"us-east-1", "us-east-2", "us-west-2"}, nil)
	uniqueId := random.UniqueId()

	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/rds-postgres")

	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"aws_region":      awsRegion,
			"name":            formatRdsName(uniqueId),
			"master_username": "username",
			"master_password": "password",
		},
	}
	setRetryParametersOnTerraformOptions(t, terraformOptions)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)
	assert.Equal(t, "5432", terraform.Output(t, terraformOptions, "postgres_port"))
	assert.Equal(t, "default.postgres9.6", terraform.Output(t, terraformOptions, "postgres_parameter_group_name"))
}

func TestRdsPostgres10(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomRegion(t, []string{"us-east-1", "us-east-2", "us-west-2"}, nil)
	uniqueId := random.UniqueId()

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/rds-postgres")

	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"aws_region":              awsRegion,
			"name":                    formatRdsName(uniqueId),
			"master_username":         "username",
			"master_password":         "password",
			"postgres_engine_version": "10.4",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)
	assert.Equal(t, "5432", terraform.Output(t, terraformOptions, "postgres_port"))
	assert.Equal(t, "default.postgres10", terraform.Output(t, terraformOptions, "postgres_parameter_group_name"))
}

func TestRdsPostgresWithCloudWatchLogs(t *testing.T) {
	t.Parallel()

	// Uncomment any of the following to skip that section during the test
	//os.Setenv("SKIP_create_test_copy_of_examples", "true")
	//os.Setenv("SKIP_create_terratest_options", "true")
	//os.Setenv("SKIP_terraform_apply", "true")
	//os.Setenv("SKIP_validate_outputs", "true")
	//os.Setenv("SKIP_validate_cloudwatch_logging", "true")
	//os.Setenv("SKIP_cleanup", "true")

	// Create a directory path that won't conflict
	workingDir := filepath.Join(".", "stages", t.Name())

	test_structure.RunTestStage(t, "create_test_copy_of_examples", func() {
		testFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
		logger.Logf(t, "path to test folder %s\n", testFolder)
		rdsPostgresTerraformModulePath := filepath.Join(testFolder, "rds-postgres")
		test_structure.SaveString(t, workingDir, "rdsPostgresTerraformModulePath", rdsPostgresTerraformModulePath)
	})

	test_structure.RunTestStage(t, "create_terratest_options", func() {
		rdsPostgresTerraformModulePath := test_structure.LoadString(t, workingDir, "rdsPostgresTerraformModulePath")
		awsRegion := aws.GetRandomRegion(t, []string{"us-east-1", "us-east-2", "us-west-2"}, nil)
		uniqueID := random.UniqueId()

		terraformOptions := &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: rdsPostgresTerraformModulePath,
			Vars: map[string]interface{}{
				"aws_region":                      awsRegion,
				"name":                            formatRdsName(uniqueID),
				"master_username":                 "username",
				"master_password":                 "password",
				"enabled_cloudwatch_logs_exports": []string{"postgresql"},
			},
		}

		test_structure.SaveString(t, workingDir, "uniqueID", uniqueID)
		test_structure.SaveString(t, workingDir, "awsRegion", awsRegion)
		test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
	})

	defer test_structure.RunTestStage(t, "cleanup", func() {
		awsRegion := test_structure.LoadString(t, workingDir, "awsRegion")
		logGroupName := test_structure.LoadString(t, workingDir, "logGroupName")
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, terraformOptions)

		// make sure we cleanup any lingering cloudwatch log groups
		cloudwatchSvc := aws.NewCloudWatchLogsClient(t, awsRegion)
		_, err := cloudwatchSvc.DeleteLogGroup(&cloudwatchlogs.DeleteLogGroupInput{
			LogGroupName: awsgo.String(logGroupName),
		})
		require.NoError(t, err)
	})

	test_structure.RunTestStage(t, "terraform_apply", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate_outputs", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		assert.Equal(t, "5432", terraform.Output(t, terraformOptions, "postgres_port"))
		assert.Equal(t, "default.postgres9.6", terraform.Output(t, terraformOptions, "postgres_parameter_group_name"))
	})

	test_structure.RunTestStage(t, "validate_cloudwatch_logging", func() {
		awsRegion := test_structure.LoadString(t, workingDir, "awsRegion")
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)

		dbName := terraform.Output(t, terraformOptions, "postgres_db_name")
		logGroupName := fmt.Sprintf("/aws/rds/instance/%s/postgresql", dbName)

		// First validate there is a log stream of the name `test{RANDOM_HASH}-postgres`. Then verify it has entries.
		// Example LogGroupName: `/aws/rds/instance/testrdwjls-postgres/postgresql`
		logger.Logf(t, "Looking up log group name: %s", logGroupName)

		cloudwatchSvc := aws.NewCloudWatchLogsClient(t, awsRegion)
		result, err := cloudwatchSvc.DescribeLogStreams(&cloudwatchlogs.DescribeLogStreamsInput{
			LogGroupName:        awsgo.String(logGroupName),
			LogStreamNamePrefix: awsgo.String(dbName),
		})
		require.NoError(t, err)
		logStreams := result.LogStreams
		require.True(t, len(logStreams) > 0)
		entries := aws.GetCloudWatchLogEntries(t, awsRegion, awsgo.StringValue(logStreams[0].LogStreamName), logGroupName)
		assert.True(t, len(entries) > 0)

		test_structure.SaveString(t, workingDir, "logGroupName", logGroupName)
	})
}
