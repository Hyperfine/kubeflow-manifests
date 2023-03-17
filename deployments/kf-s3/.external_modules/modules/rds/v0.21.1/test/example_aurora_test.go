package test

import (
	"fmt"
	"strings"
	"testing"

	goaws "github.com/aws/aws-sdk-go/aws"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
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

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/aurora")

	awsRegion := getAuroraRegion(t)
	uniqueId := random.UniqueId()
	rdsName := formatRdsName(uniqueId)
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"aws_region":      awsRegion,
			"name":            rdsName,
			"instance_count":  "1",
			"master_username": "username",
			"master_password": "password",
		},
	}
	setRetryParametersOnTerraformOptions(t, terraformOptions)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer func() {
		terraform.Destroy(t, terraformOptions)
	}()
	terraform.InitAndApply(t, terraformOptions)
	assert.Equal(t, "3306", terraform.Output(t, terraformOptions, "port_1"))

	// Now test that we can immediately modify the instance
	terraformOptions.Vars["instance_type"] = "db.t3.medium"
	terraform.Apply(t, terraformOptions)

	// Verify that the instance was immediately updated
	dbInstanceIDs1 := terraform.OutputList(t, terraformOptions, "instance_ids_1")
	dbInstanceIDs2 := terraform.OutputList(t, terraformOptions, "instance_ids_2")
	for _, dbInstanceID := range append(dbInstanceIDs1, dbInstanceIDs2...) {
		dbInstance, err := aws.GetRdsInstanceDetailsE(t, dbInstanceID, awsRegion)
		require.NoError(t, err)
		assert.Equal(t, "db.t3.medium", goaws.StringValue(dbInstance.DBInstanceClass))
	}
}

// A basic sanity check of the Aurora Serverless example that just deploys and undeploys it to make sure there are no
// errors in the templates.
// TODO: try to actually connect to the Aurora DB and check it's working
func TestAuroraWithServerlessEngine(t *testing.T) {
	t.Parallel()

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/aurora-serverless")

	awsRegion := getAuroraRegion(t)
	uniqueID := random.UniqueId()
	rdsName := formatRdsName(uniqueID)
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"aws_region":      awsRegion,
			"name":            rdsName,
			"master_username": "username",
			"master_password": "password",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer func() {
		terraform.Destroy(t, terraformOptions)
	}()

	terraform.InitAndApply(t, terraformOptions)
	assert.Equal(t, "3306", terraform.Output(t, terraformOptions, "port"))
}

// These should be refactored to use a different test style here later...

func TestFailWhenEncryptionIsFalseAndEngineIsServerless(t *testing.T) {
	t.Parallel()
	t.Skip("Skipping until the assertion we're trying to test in the code can be fixed")

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/aurora")

	uniqueId := random.UniqueId()
	awsRegion := getAuroraRegion(t)
	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
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

// Test the create_subnet_group flag to disable the subnet_group that's normally created by the aurora module.
func TestAuroraWithExternalSubnetGroup(t *testing.T) {
	t.Parallel()

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/aurora")

	awsRegion := getAuroraRegion(t)
	uniqueId := random.UniqueId()
	rdsName := formatRdsName(uniqueId)
	dbSubnetGroupName := strings.ToLower(fmt.Sprintf("%s-%s", t.Name(), uniqueId))

	defer deleteTestDbSubnetGroup(t, awsRegion, dbSubnetGroupName)
	createTestDbSubnetGroup(t, awsRegion, dbSubnetGroupName)

	// Create a db subnet group externally that will be fed into the module

	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"aws_region":               awsRegion,
			"name":                     rdsName,
			"instance_count":           "1",
			"master_username":          "username",
			"master_password":          "password",
			"create_subnet_group":      false,
			"aws_db_subnet_group_name": dbSubnetGroupName,
		},
	}
	setRetryParametersOnTerraformOptions(t, terraformOptions)

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
