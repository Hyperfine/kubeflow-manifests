package test

import (
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
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

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)
	assert.Equal(t, "5432", terraform.Output(t, terraformOptions, "postgres_port"))
	assert.Equal(t, "default.postgres9.4", terraform.Output(t, terraformOptions, "postgres_parameter_group_name"))
}

func TestRdsPostgres10(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomRegion(t, []string{"us-east-1", "us-east-2", "us-west-2"}, nil)
	uniqueId := random.UniqueId()

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
