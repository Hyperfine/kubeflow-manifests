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

const SQS_DLQ_PATH = "examples/sqs/dead-letter-queue"

func TestSQSOptionality(t *testing.T) {
	t.Parallel()

	exampleDir := test_structure.CopyTerraformFolderToTemp(t, REPO_ROOT, SQS_DLQ_PATH)

	awsRegion := aws.GetRandomRegion(t, nil, FORBIDDEN_REGIONS)
	uniqueId := random.UniqueId()
	queueName := fmt.Sprintf("test-queue-%s", uniqueId)
	terraformOptions := createTerratestOptionsForSQS(exampleDir, awsRegion, queueName)
	terraformOptions.Vars["create_resources"] = false
	terraformOptions.PlanFilePath = filepath.Join(exampleDir, "plan.tfplan")

	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	assert.Equal(t, 0, len(planStruct.ResourcePlannedValuesMap))
	assert.Equal(t, 0, len(planStruct.ResourceChangesMap))
}

func TestSQSDeadLetterQueue(t *testing.T) {
	t.Parallel()

	// os.Setenv("SKIP_bootstrap", "true")
	// os.Setenv("SKIP_deploy", "true")
	// os.Setenv("SKIP_validate_outputs", "true")
	// os.Setenv("SKIP_teardown", "true")

	exampleDir := test_structure.CopyTerraformFolderToTemp(t, REPO_ROOT, SQS_DLQ_PATH)

	test_structure.RunTestStage(t, "bootstrap", func() {
		awsRegion := aws.GetRandomRegion(t, nil, FORBIDDEN_REGIONS)
		uniqueId := random.UniqueId()
		queueName := fmt.Sprintf("test-queue-%s", uniqueId)

		terraformOptions := createTerratestOptionsForSQS(exampleDir, awsRegion, queueName)
		test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)
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

		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "sqs_tests", func() {
		logger.Logf(t, "Running SQS Tests")

		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)

		region := test_structure.LoadString(t, exampleDir, KEY_REGION)
		queueUrl := terraform.Output(t, terraformOptions, OUTPUT_SQS_QUEUE)
		dlQueueUrl := terraform.Output(t, terraformOptions, OUTPUT_SQS_DLQUEUE)

		err := aws.SendMessageToQueueE(t, region, queueUrl, "TestMessage")
		require.NoError(t, err, "Failed to send a message to %s", queueUrl)

		err = aws.SendMessageToQueueE(t, region, dlQueueUrl, "TestMessage")
		require.NoError(t, err, "Failed to send a message to %s", dlQueueUrl)
	})
}
