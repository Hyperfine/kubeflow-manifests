package test

import (
	"fmt"
	"path/filepath"
	"strconv"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func TestKinesis(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_bootstrap", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_validate_outputs", "true")
	//os.Setenv("SKIP_teardown", "true")

	var testcases = []struct {
		testName         string
		encryptionType   string
		numShards        int
		expectedShards   int
		recordsPerSecond int
		numConsumers     int
		avgDataSize      int
		retentionPeriod  int
	}{
		{
			"ManualShards",
			"NONE",
			2,
			2,
			0,
			0,
			0,
			34,
		},
		{
			"ManualShardsWithEncryption",
			"KMS",
			3,
			3,
			0,
			0,
			0,
			36,
		},
		{
			"AutoShards",
			"NONE",
			-1,
			6,
			50,
			10,
			25,
			45,
		},
	}

	for _, testCase := range testcases {
		// The following is necessary to make sure testCase's values don't
		// get updated due to concurrency within the scope of t.Run(..) below
		testCase := testCase

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()

			_examplesDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples")
			exampleDir := filepath.Join(_examplesDir, "kinesis")

			test_structure.RunTestStage(t, "bootstrap", func() {
				awsRegion := aws.GetRandomRegion(t, []string{}, []string{})
				uniqueId := random.UniqueId()
				streamName := fmt.Sprintf("test-stream-%s", uniqueId)

				test_structure.SaveString(t, exampleDir, KEY_KINESIS_STREAM_NAME, streamName)
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
				streamName := test_structure.LoadString(t, exampleDir, KEY_KINESIS_STREAM_NAME)
				terraformOptions := createTerratestOptionsForKinesis(exampleDir, region, streamName, testCase.numShards, testCase.encryptionType, testCase.avgDataSize, testCase.recordsPerSecond, testCase.numConsumers, testCase.retentionPeriod)
				test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)

				terraform.InitAndApply(t, terraformOptions)
			})

			test_structure.RunTestStage(t, "validate_outputs", func() {
				logger.Logf(t, "Validating outputs")

				terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)

				actualShards := terraform.Output(t, terraformOptions, OUTPUT_KINESIS_SHARD_COUNT)
				actualEncType := terraform.Output(t, terraformOptions, OUTPUT_KINESIS_ENC_TYPE)
				actualRetention := terraform.Output(t, terraformOptions, OUTPUT_KINESIS_RETENTION)

				actualShardsInt, _ := strconv.Atoi(actualShards)
				actualRetentionInt, _ := strconv.Atoi(actualRetention)

				assert.Equal(t, testCase.expectedShards, actualShardsInt, "Number of shards")
				assert.Equal(t, testCase.encryptionType, actualEncType, "Encryption type")
				assert.Equal(t, testCase.retentionPeriod, actualRetentionInt, "Retention period")
			})
		})
	}
}
