package test

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

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

	// Uncomment the items below to skip some of the test stages
	//os.Setenv("TERRATEST_REGION", "eu-west-1")
	//os.Setenv("SKIP_undeploy", "true")
	//os.Setenv("SKIP_cleanup_snapshots", "true")
	//os.Setenv("SKIP_configure", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_trigger_lambdas", "true")
	//os.Setenv("SKIP_validate", "true")

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/lambda-rds-snapshot")

	defer test_structure.RunTestStage(t, "undeploy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, terraformDir)
		terraform.Destroy(t, terraformOptions)
	})

	defer test_structure.RunTestStage(t, "cleanup_snapshots", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, terraformDir)

		region, ok := terraformOptions.Vars["aws_region"].(string)
		require.True(t, ok)

		mySqlCleanupSnapshotsLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "mysql_cleanup_snapshots_lambda_arn")
		mySqlDbIdentifier := getRequiredTerraformOutput(t, terraformOptions, "mysql_primary_id")

		auroraCleanupSnapshotsLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "aurora_cleanup_snapshots_lambda_arn")
		auroraDbIdentifier := getRequiredTerraformOutput(t, terraformOptions, "aurora_cluster_id")

		cleanupSnapshot(t, mySqlCleanupSnapshotsLambdaArn, mySqlDbIdentifier, false, region, "")
		cleanupSnapshot(t, auroraCleanupSnapshotsLambdaArn, auroraDbIdentifier, true, region, "")
	})

	test_structure.RunTestStage(t, "configure", func() {
		uniqueId := random.UniqueId()
		region := getAuroraRegion(t)

		terraformOptions := &terraform.Options{
			TerraformDir: terraformDir,
			Vars: map[string]interface{}{
				"aws_region":          region,
				"name":                formatRdsName(uniqueId),
				"master_username":     "username",
				"master_password":     "password",
				"external_account_id": getExternalAccountId(),

				// Set to a long time so the lambda function never runs automatically during this test. Instead,
				// we'll trigger it manually.
				"schedule_expression": "rate(5 hours)",

				// This is used to clean up all snapshots at the end of the test... Which is also how we'll verify that
				// the lambda-cleanup-snapshots module works correctly
				"max_snapshots":    0,
				"allow_delete_all": true,
			},
		}
		setRetryParametersOnTerraformOptions(t, terraformOptions)

		test_structure.SaveTerraformOptions(t, terraformDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, terraformDir)
		logger.Log(t, "Deploying terraform code in %s", terraformOptions.TerraformDir)
		deploy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "trigger_lambdas", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, terraformDir)

		region, ok := terraformOptions.Vars["aws_region"].(string)
		require.True(t, ok)

		mySqlCreateSnapshotLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "mysql_create_snapshot_lambda_arn")
		auroraCreateSnapshotLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "aurora_create_snapshot_lambda_arn")

		triggerLambdaFunction(t, mySqlCreateSnapshotLambdaArn, region)
		triggerLambdaFunction(t, auroraCreateSnapshotLambdaArn, region)
	})

	test_structure.RunTestStage(t, "validate", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, terraformDir)

		mySqlDbIdentifier := getRequiredTerraformOutput(t, terraformOptions, "mysql_primary_id")
		auroraDbIdentifier := getRequiredTerraformOutput(t, terraformOptions, "aurora_cluster_id")

		region, ok := terraformOptions.Vars["aws_region"].(string)
		require.True(t, ok)

		validateSnapshotExists(t, mySqlDbIdentifier, false, region, true)
		validateSnapshotExists(t, auroraDbIdentifier, true, region, true)

		checkForPerpetualDiff(t, terraformOptions)

		// TODO: add a test for lambda-copy-shared-snapshot module; to do that, we'll need some external AWS account to
		// share a snapshot with this account
	})
}
