package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// A basic sanity check of the Redshift example that just deploys and undeploys it to make sure there are no errors in
// the templates
func TestRedshift(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomRegion(t, []string{"us-east-1", "us-east-2", "us-west-2"}, nil)
	uniqueId := random.UniqueId()

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/redshift")

	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"aws_region":      awsRegion,
			"name":            formatRdsName(uniqueId),
			"master_username": "username",
			"master_password": "Password1!",
		},
	}
	setRetryParametersOnTerraformOptions(t, terraformOptions)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)
	assert.Equal(t, "5439", terraform.Output(t, terraformOptions, "port"))
	assert.Equal(t, "default.redshift-1.0", terraform.Output(t, terraformOptions, "parameter_group_name"))
}

// Test the create_subnet_group flag to disable the subnet_group that's normally created by the rds module.
func TestRedshiftWithExternalSubnetGroup(t *testing.T) {
	t.Parallel()

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/redshift")

	awsRegion := aws.GetRandomRegion(t, []string{"us-east-1", "us-east-2", "us-west-2"}, nil)
	uniqueId := random.UniqueId()
	rdsName := formatRdsName(uniqueId)
	redshiftSubnetGroupName := strings.ToLower(fmt.Sprintf("%s-%s", t.Name(), uniqueId))

	defer deleteTestRedshiftSubnetGroup(t, awsRegion, redshiftSubnetGroupName)
	createTestRedshiftSubnetGroup(t, awsRegion, redshiftSubnetGroupName)

	// Create a db subnet group externally that will be fed into the module

	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"aws_region":                awsRegion,
			"name":                      rdsName,
			"master_username":           "username",
			"master_password":           "Password1!",
			"create_subnet_group":       false,
			"cluster_subnet_group_name": redshiftSubnetGroupName,
		},
	}
	setRetryParametersOnTerraformOptions(t, terraformOptions)

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
