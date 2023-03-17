package test

import (
	"fmt"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSQSOptionality(t *testing.T) {
	t.Parallel()

	_examplesDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples")
	exampleDir := filepath.Join(_examplesDir, "sqs/dead-letter-queue")

	awsRegion := aws.GetRandomRegion(t, []string{}, []string{})
	uniqueId := random.UniqueId()
	queueName := fmt.Sprintf("test-queue-%s", uniqueId)
	terraformOptions := createTerratestOptionsForSQS(exampleDir, awsRegion, queueName)
	terraformOptions.Vars["create_resources"] = false

	planOut := terraform.InitAndPlan(t, terraformOptions)
	planCounts := terraform.GetResourceCount(t, planOut)
	assert.Equal(t, planCounts.Add, 0)
	assert.Equal(t, planCounts.Change, 0)
	assert.Equal(t, planCounts.Destroy, 0)
}

func TestSQSStandardQueue(t *testing.T) {
	t.Parallel()

	_examplesDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples")
	exampleDir := filepath.Join(_examplesDir, "sqs/dead-letter-queue")

	test_structure.RunTestStage(t, "bootstrap", func() {
		awsRegion := aws.GetRandomRegion(t, []string{}, []string{})
		uniqueId := random.UniqueId()
		queueName := fmt.Sprintf("test-queue-%s", uniqueId)

		test_structure.SaveString(t, exampleDir, KEY_SQS_QUEUE_NAME, queueName)
		test_structure.SaveString(t, exampleDir, KEY_REGION, awsRegion)
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer test_structure.RunTestStage(t, "teardown", func() {
		logger.Logf(t, "Tear down infrastructure")

		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		logger.Logf(t, "Deploying infrastructure")

		region := test_structure.LoadString(t, exampleDir, KEY_REGION)
		queueName := test_structure.LoadString(t, exampleDir, KEY_SQS_QUEUE_NAME)
		terraformOptions := createTerratestOptionsForSQS(exampleDir, region, queueName)
		test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)

		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "sqs_tests", func() {

		logger.Logf(t, "Running SQS Tests")

		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)

		region := test_structure.LoadString(t, exampleDir, KEY_REGION)

		queueUrl := terraform.Output(t, terraformOptions, OUTPUT_SQS_QUEUE)

		err := aws.SendMessageToQueueE(t, region, queueUrl, "TestMessage")
		require.NoError(t, err, "Failed to send a message to %s", queueUrl)
	})
}
