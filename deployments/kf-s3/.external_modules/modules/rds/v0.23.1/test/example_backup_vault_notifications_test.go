package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

/*

N.B. This test currently ensures that the configurations for the target example are valid, and that they can be planned, applied and destroyed successfully without error.

This test DOES NOT yet ensure that actual backup recovery points are created following a successful backup job.

This limitation is temporary, as we are currently planning to develop a reasonable strategy for testing the creation of backup recovery points.

Given the asynchronous and potentially expensive nature of AWS backup's functionality, we want to avoid edge cases resulting in unexpected account charges.
*/
func TestDeployVaultWithNotifications(t *testing.T) {

	t.Parallel()

	testFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/vault-notifications")

	defer test_structure.RunTestStage(t, "cleanup", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {

		awsRegion := aws.GetRandomRegion(t, nil, nil)
		test_structure.SaveString(t, testFolder, "region", awsRegion)

		name := random.UniqueId()
		test_structure.SaveString(t, testFolder, "name", name)
		serviceRoleName := fmt.Sprintf("%s-%s", name, "backup-service-role")
		test_structure.SaveString(t, testFolder, "serviceRoleName", serviceRoleName)

		terraformOptions := CreateBaseTerraformOptions(t, testFolder, awsRegion)
		terraformOptions.Vars["name"] = name
		terraformOptions.Vars["backup_service_role_name"] = serviceRoleName

		test_structure.SaveTerraformOptions(t, testFolder, terraformOptions)

	})

	test_structure.RunTestStage(t, "deploy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		terraform.InitAndApply(t, terraformOptions)
	})

}
