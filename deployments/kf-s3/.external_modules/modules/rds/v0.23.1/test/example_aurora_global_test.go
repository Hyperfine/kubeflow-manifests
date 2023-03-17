package test

import (
	"path/filepath"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/iam"
	terraws "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

func TestAuroraWithGlobalEngine(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_setup", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_validate", "true")
	//os.Setenv("SKIP_teardown", "true")

	// Create a directory path that won't conflict
	workingDir := filepath.Join(".", "stages", t.Name())

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/aurora-global-cluster")

	test_structure.RunTestStage(t, "setup", func() {
		uniqueID := random.UniqueId()
		rdsName := formatRdsName(uniqueID)
		test_structure.SaveString(t, workingDir, "name", rdsName)
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		rdsName := test_structure.LoadString(t, workingDir, "name")

		// Get the current IAM User's ARN. If we were to set the Key Administrator to a user other than the current IAM
		// User, only that user -- and not the user operating this test session! -- could delete the key, and AWS warns
		// us accordingly. So, we always want to use the current IAM User for testing purposes.
		// NOTE: This section will need to be commented out and replaced with the following if you are running this test
		// locally
		// currentIamUserArn := "arn:aws:iam::ID_OF_SANDBOX_OF_TEST_ACCOUNT:role/allow-full-access-from-other-accounts"
		sess, err := terraws.NewAuthenticatedSession("us-east-1")
		require.NoError(t, err)
		iamClient := iam.New(sess)
		output, err := iamClient.GetUser(&iam.GetUserInput{})
		require.NoError(t, err)
		currentIamUserArn := aws.StringValue(output.User.Arn)

		terraformOptions := &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: terraformDir,
			Vars: map[string]interface{}{
				"aws_region":                 "us-east-1",
				"replica_region":             "us-east-2",
				"name":                       rdsName,
				"instance_count":             "1",
				"master_username":            "username",
				"master_password":            "password",
				"storage_encrypted":          true,
				"cmk_administrator_iam_arns": []string{currentIamUserArn},
				"cmk_user_iam_arns":          []interface{}{},
			},
		}
		setRetryParametersOnTerraformOptions(t, terraformOptions)
		test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		port := terraform.Output(t, terraformOptions, "port")
		primaryEndpoint := terraform.Output(t, terraformOptions, "cluster_endpoint")
		primaryServer := RDSInfo{
			Username:   "username",
			Password:   "password",
			DBName:     "postgres",
			DBEndpoint: primaryEndpoint,
			DBPort:     port,
		}
		replicaEndpoint := terraform.OutputList(t, terraformOptions, "replica_instance_endpoints")[0]
		replicaServer := RDSInfo{
			Username:   "username",
			Password:   "password",
			DBName:     "postgres",
			DBEndpoint: replicaEndpoint,
			DBPort:     port,
		}

		// First, test connectivity and activeness of the primary and replicas
		smokeTestPostgres(t, primaryServer)
		smokeTestPostgres(t, replicaServer)

		// Next, verify replication by creating a new DB in the primary and checking if we can access it in the replica
		newDBName := "newdatabase"
		createPostgresDB(t, primaryServer, newDBName)
		primaryServer.DBName = newDBName
		replicaServer.DBName = newDBName
		smokeTestPostgres(t, primaryServer)
		smokeTestPostgres(t, replicaServer)
	})
}
