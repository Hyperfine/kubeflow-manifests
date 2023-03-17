package test

import (
	"fmt"
	"strconv"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

const KINESIS_PATH = "examples/kinesis"

type kinesisTestCase struct {
	Name             string
	EncryptionType   string
	NumShards        int
	ExpectedShards   int
	RecordsPerSecond int
	NumConsumers     int
	AvgDataSize      int
	RetentionPeriod  int
}

func TestKinesis(t *testing.T) {
	t.Parallel()

	// os.Setenv("SKIP_bootstrap", "true")
	// os.Setenv("SKIP_deploy", "true")
	// os.Setenv("SKIP_validate_outputs", "true")
	// os.Setenv("SKIP_teardown", "true")

	var testcases = []kinesisTestCase{
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

		t.Run(testCase.Name, func(t *testing.T) {
			t.Parallel()

			exampleDir := test_structure.CopyTerraformFolderToTemp(t, REPO_ROOT, KINESIS_PATH)

			test_structure.RunTestStage(t, "bootstrap", func() {
				awsRegion := aws.GetRandomRegion(t, nil, FORBIDDEN_REGIONS)
				uniqueId := random.UniqueId()
				streamName := fmt.Sprintf("test-stream-%s", uniqueId)
				terraformOptions := createTerratestOptionsForKinesis(exampleDir, awsRegion, streamName, testCase.NumShards, testCase.EncryptionType, testCase.AvgDataSize, testCase.RecordsPerSecond, testCase.NumConsumers, testCase.RetentionPeriod)
				test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)
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

			test_structure.RunTestStage(t, "validate_outputs", func() {
				logger.Logf(t, "Validating outputs")

				terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)

				actualShards := terraform.Output(t, terraformOptions, OUTPUT_KINESIS_SHARD_COUNT)
				actualEncType := terraform.Output(t, terraformOptions, OUTPUT_KINESIS_ENC_TYPE)
				actualRetention := terraform.Output(t, terraformOptions, OUTPUT_KINESIS_RETENTION)

				actualShardsInt, _ := strconv.Atoi(actualShards)
				actualRetentionInt, _ := strconv.Atoi(actualRetention)

				assert.Equal(t, testCase.ExpectedShards, actualShardsInt, "Number of shards")
				assert.Equal(t, testCase.EncryptionType, actualEncType, "Encryption type")
				assert.Equal(t, testCase.RetentionPeriod, actualRetentionInt, "Retention period")
			})
		})
	}
}
