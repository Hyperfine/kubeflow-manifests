package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// A basic sanity check of the EFS example that just deploys and undeploys it to make sure there are no errors in
// the templates
func TestEfs(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomRegion(t, []string{"us-east-1", "us-east-2", "us-west-2"}, nil)
	uniqueId := random.UniqueId()

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/efs")

	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"aws_region": awsRegion,
			"name":       formatRdsName(uniqueId),
		},
	}
	setRetryParametersOnTerraformOptions(t, terraformOptions)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)
	assert.Equal(t, formatEfsDnsName(terraform.Output(t, terraformOptions, "id"), awsRegion), terraform.Output(t, terraformOptions, "dns_name"))
}

func formatEfsDnsName(id string, region string) string {
	return id + ".efs." + region + ".amazonaws.com"
}
