package test

import (
	"fmt"
	"path/filepath"
	"testing"

	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

func TestSQSEncryptedQueue(t *testing.T) {
	t.Parallel()

	_examplesDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples")
	exampleDir := filepath.Join(_examplesDir, "sqs/fifo-queue-with-encryption")

	test_structure.RunTestStage(t, "bootstrap", func() {
		awsRegion := aws.GetRandomRegion(t, []string{}, REGIONS_WITHOUT_FIFO_QUEUES)
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

		err := SendMessageToFIFOQueue(t, region, queueUrl)
		require.NoError(t, err, "Failed to send a message to %s", queueUrl)
	})
}

func SendMessageToFIFOQueue(t *testing.T, region string, queue string) error {
	sqsClient, err := aws.NewSqsClientE(t, region)

	require.NoError(t, err, "Failed to create SQS Client in %s", region)

	message := "TestMessage"
	randomId := random.UniqueId()

	_, err = sqsClient.SendMessage(&sqs.SendMessageInput{
		MessageBody:            &message,
		QueueUrl:               &queue,
		MessageGroupId:         &randomId,
		MessageDeduplicationId: &randomId,
	})

	return err
}
