package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func TestRdsMySqlWithCrossRegionReplica(t *testing.T) {
	t.Parallel()

	uniqueId := random.UniqueId()
	testFolder := "../examples/rds-mysql-with-cross-region-replica"

	// You can uncommment these to skip some of the test stages below
	//os.Setenv("SKIP_undeploy", "true")
	//os.Setenv("SKIP_config", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_validate", "true")

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer test_structure.RunTestStage(t, "undeploy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		terraform.Destroy(t, terraformOptions)
	})

	// Configure test params
	test_structure.RunTestStage(t, "config", func() {
		terraformOptions := &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: "../examples/rds-mysql-with-cross-region-replica",
			Vars: map[string]interface{}{
				"name":              formatRdsName(uniqueId),
				"master_username":   "username",
				"master_password":   "password",
				"storage_encrypted": "false",
			},
		}
		setRetryParametersOnTerraformOptions(t, terraformOptions)

		test_structure.SaveTerraformOptions(t, testFolder, terraformOptions)
	})

	// Just make sure it all deploys
	test_structure.RunTestStage(t, "deploy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		terraform.InitAndApply(t, terraformOptions)
	})

	// Minimal sanity checks
	test_structure.RunTestStage(t, "validate", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		assert.Equal(t, "3306", terraform.Output(t, terraformOptions, "mysql_primary_port"))
		assert.Equal(t, "3306", terraform.Output(t, terraformOptions, "mysql_replica_port"))
	})
}
