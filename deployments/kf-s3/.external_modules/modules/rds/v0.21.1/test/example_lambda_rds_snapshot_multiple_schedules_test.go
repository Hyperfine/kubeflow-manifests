package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

// This test does the following:
//
// 1. Deploy the lambda-rds-snapshot-multiple-schedules example
// 2. Trigger both of the lambda-create-snapshot functions to create snapshots of the MySQL DB
// 4. Validate that the snapshots get created with the proper names
// 5. Trigger each lambda-cleanup-snapshots function to cleanup the snapshots
// 6. Validate that the right snapshots have been deleted
func TestLambdaRdsSnapshotMultipleSchedules(t *testing.T) {
	t.Parallel()

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/lambda-rds-snapshot-multiple-schedules")

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

			// This is used to clean up all snapshots at the end of the test... Which is also how we'll verify that
			// the lambda-cleanup-snapshots module works correctly
			"max_hourly_snapshots": 0,
			"max_weekly_snapshots": 0,
			"allow_delete_all":     true,
		},
	}
	setRetryParametersOnTerraformOptions(t, terraformOptions)

	defer terraform.Destroy(t, terraformOptions)

	logger.Log(t, "Deploying terraform code in %s", terraformOptions.TerraformDir)
	deploy(t, terraformOptions)

	dbIdentifier := getRequiredTerraformOutput(t, terraformOptions, "mysql_primary_id")

	hourlyCreateSnapshotLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "create_hourly_snapshot_lambda_arn")
	hourlyCleanupSnapshotsLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "cleanup_hourly_snapshots_lambda_arn")
	weeklyCreateSnapshotLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "create_weekly_snapshot_lambda_arn")
	weeklyCleanupSnapshotsLambdaArn := getRequiredTerraformOutput(t, terraformOptions, "cleanup_weekly_snapshots_lambda_arn")

	triggerLambdaFunction(t, hourlyCreateSnapshotLambdaArn, region)
	defer cleanupSnapshot(t, hourlyCleanupSnapshotsLambdaArn, dbIdentifier, false, region, "-hourly")

	triggerLambdaFunction(t, weeklyCreateSnapshotLambdaArn, region)
	defer cleanupSnapshot(t, weeklyCleanupSnapshotsLambdaArn, dbIdentifier, false, region, "-weekly")

	validateSnapshotSuffixExists(t, dbIdentifier, false, region, false, "-hourly")
	validateSnapshotSuffixExists(t, dbIdentifier, false, region, false, "-weekly")

	checkForPerpetualDiff(t, terraformOptions)
}
