package test

import (
	"encoding/json"
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TODO: figure out a way to:
// 1) make the Lambda alarms go off,
// 2) subscribe to the SNS topic, and
// 3) check that you get notifications for the alarms
func TestLambdaAlarms(t *testing.T) {
	t.Parallel()

	// Uncomment the items below to skip certain parts of the test
	// os.Setenv("TERRATEST_REGION", "us-east-1")
	// os.Setenv("SKIP_setup", "true")
	// os.Setenv("SKIP_build_lambda", "true")
	// os.Setenv("SKIP_deploy_lambda", "true")
	// os.Setenv("SKIP_validate_lambda", "true")
	// os.Setenv("SKIP_cleanup", "true")
	// os.Setenv("SKIP_cleanup_lambda", "true")

	testFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "examples/lambda-alarms")

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomRegion(t, nil, nil)
		name := fmt.Sprintf("lambda-%s", random.UniqueId())
		snsTopicName := fmt.Sprintf("%s-sns-topic", name)

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: testFolder,
			Vars: map[string]interface{}{
				"aws_region":     awsRegion,
				"name":           name,
				"sns_topic_name": snsTopicName,
			},
		})

		test_structure.SaveTerraformOptions(t, testFolder, terraformOptions)
		test_structure.SaveString(t, testFolder, "aws_region", awsRegion)
		test_structure.SaveString(t, testFolder, "name", name)
	})

	defer test_structure.RunTestStage(t, "cleanup_lambda", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		cleanupLambdaArtifacts(t, terraformOptions)
	})

	defer test_structure.RunTestStage(t, "cleanup", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "build_lambda", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		buildLambdaArtifacts(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_lambda", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate_lambda", func() {
		awsRegion := test_structure.LoadString(t, testFolder, "aws_region")
		name := test_structure.LoadString(t, testFolder, "name")

		validateLambda(t, awsRegion, name)
	})
}

func cleanupLambdaArtifacts(t *testing.T, terraformOptions *terraform.Options) {
	err := os.RemoveAll(terraformOptions.TerraformDir)
	require.NoError(t, err)
}

func buildLambdaArtifacts(t *testing.T, terraformOptions *terraform.Options) {
	command := shell.Command{
		Command:    "./python/build.sh",
		WorkingDir: terraformOptions.TerraformDir,
	}
	shell.RunCommand(t, command)
}

type Response struct {
	Status int
}

func validateLambda(t *testing.T, awsRegion string, name string) {
	payload := map[string]string{
		"url": "http://www.example.com",
	}

	out := aws.InvokeFunction(t, awsRegion, name, payload)

	var response Response
	err := json.Unmarshal([]byte(out), &response)
	require.NoError(t, err)

	assert.Equal(t, 200, response.Status)
}
