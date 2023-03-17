package test

import (
	"fmt"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func getAuroraRegion(t *testing.T) string {
	// Aurora is not available in all regions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Aurora.html#d0e64378
	return aws.GetRandomRegion(t, []string{"us-east-1", "us-east-2", "us-west-2"}, nil)
}

// A basic sanity check of the Aurora example that just deploys and undeploys it to make sure there are no errors in
// the templates
// TODO: try to actually connect to the Aurora DB and check it's working
func TestAurora(t *testing.T) {
	t.Parallel()

	testFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
	terraformModulePath := filepath.Join(testFolder, "aurora")
	logger.Logf(t, "path %s\n", terraformModulePath)

	awsRegion := getAuroraRegion(t)
	uniqueId := random.UniqueId()
	rdsName := formatRdsName(uniqueId)
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: terraformModulePath,
		Vars: map[string]interface{}{
			"aws_region":      awsRegion,
			"name":            rdsName,
			"instance_count":  "1",
			"master_username": "username",
			"master_password": "password",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer func() {
		terraform.Destroy(t, terraformOptions)

		// When we destroy the DB, we also create a final snapshot. This will build up over time, so we clean it up
		// here.
		auroraName1 := fmt.Sprintf("%s-1", rdsName)
		deleteFinalSnapshot(t, awsRegion, auroraName1)
		auroraName2 := fmt.Sprintf("%s-2", rdsName)
		deleteFinalSnapshot(t, awsRegion, auroraName2)
	}()
	terraform.InitAndApply(t, terraformOptions)
	assert.Equal(t, "3306", terraform.Output(t, terraformOptions, "port_1"))
}

// A basic sanity check of the Aurora example that just deploys and undeploys it to make sure there are no errors in
// the templates
// TODO: try to actually connect to the Aurora DB and check it's working
func TestAuroraWithServerlessEngine(t *testing.T) {
	t.Parallel()

	testFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
	terraformModulePath := filepath.Join(testFolder, "aurora")
	logger.Logf(t, "path %s\n", terraformModulePath)

	awsRegion := getAuroraRegion(t)
	uniqueId := random.UniqueId()
	rdsName := formatRdsName(uniqueId)
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: terraformModulePath,
		Vars: map[string]interface{}{
			"aws_region":        awsRegion,
			"name":              rdsName,
			"instance_count":    "1",
			"master_username":   "username",
			"master_password":   "password",
			"engine_mode":       "serverless",
			"storage_encrypted": true,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer func() {
		terraform.Destroy(t, terraformOptions)

		// When we destroy the DB, we also create a final snapshot. This will build up over time, so we clean it up
		// here.
		auroraName1 := fmt.Sprintf("%s-1", rdsName)
		deleteFinalSnapshot(t, awsRegion, auroraName1)
		auroraName2 := fmt.Sprintf("%s-2", rdsName)
		deleteFinalSnapshot(t, awsRegion, auroraName2)
	}()

	terraform.InitAndApply(t, terraformOptions)
	assert.Equal(t, "3306", terraform.Output(t, terraformOptions, "port_1"))
}

// These should be refactored to use a different test style here later...

func TestFailWhenEncryptionIsFalseAndEngineIsServerless(t *testing.T) {
	t.Parallel()
	t.Skip("Skipping until the assertion we're trying to test in the code can be fixed")

	testFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
	terraformModulePath := filepath.Join(testFolder, "aurora")
	logger.Logf(t, "path %s\n", terraformModulePath)

	uniqueId := random.UniqueId()
	awsRegion := getAuroraRegion(t)
	terraformOptions := &terraform.Options{
		TerraformDir: terraformModulePath,
		Vars: map[string]interface{}{
			"aws_region":        awsRegion,
			"name":              formatRdsName(uniqueId),
			"instance_count":    "1",
			"master_username":   "username",
			"master_password":   "password",
			"engine_mode":       "serverless",
			"storage_encrypted": false,
		},
	}

	defer terraform.DestroyE(t, terraformOptions)
	_, err := terraform.InitAndApplyE(t, terraformOptions)
	require.Error(t, err)
}
