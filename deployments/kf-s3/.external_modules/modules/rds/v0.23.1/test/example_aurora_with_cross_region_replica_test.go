package test

import (
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/iam"
	terraws "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/require"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// A basic sanity check of the Aurora example that just deploys and undeploys it to make sure there are no errors in
// the templates
// TODO: try to actually connect to the Aurora DB and check it's working
func TestAuroraWithCrossRegionReplica(t *testing.T) {
	t.Parallel()

	// Create a test copy of the example
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/aurora-with-cross-region-replica")
	uniqueId := random.UniqueId()
	rdsName := formatRdsName(uniqueId)
	primaryRegion := "us-east-1"
	replicaRegion := "us-east-2"

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
			"primary_region":             primaryRegion,
			"replica_region":             replicaRegion,
			"name":                       rdsName,
			"instance_count":             "1",
			"master_username":            "username",
			"master_password":            "password",
			"cmk_administrator_iam_arns": []string{currentIamUserArn},
			"cmk_user_iam_arns":          []interface{}{},
		},
	}
	setRetryParametersOnTerraformOptions(t, terraformOptions)

	// We run a plan for basic validation that there are no errors in the templates.
	// We don't do an actual apply/destroy here because read replicas can't be destroyed
	// without first promoting them to primary clusters.
	planOut := terraform.InitAndPlan(t, terraformOptions)
	resourceCounts := terraform.GetResourceCount(t, planOut)
	assert.Equal(t, 19, resourceCounts.Add) // It is not 0, because we have the DB resources to create
	assert.Equal(t, 0, resourceCounts.Change)
	assert.Equal(t, 0, resourceCounts.Destroy)
}
