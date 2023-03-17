package test

import (
	"fmt"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestSNS(t *testing.T) {
	t.Parallel()

	userArn := aws.GetIamCurrentUserArn(t)

	var testcases = []struct {
		testName       string
		allowPublish   []string
		allowSubscribe []string
	}{
		{
			"AllowBoth",
			[]string{userArn},
			[]string{userArn},
		},
		{
			"AllowPublish",
			[]string{userArn},
			[]string{},
		},
		{
			"AllowSub",
			[]string{},
			[]string{userArn},
		},
		{
			"AllowNone",
			[]string{},
			[]string{},
		},
	}

	for _, testCase := range testcases {
		// The following is necessary to make sure testCase's values don't
		// get updated due to concurrency within the scope of t.Run(..) below
		testCase := testCase

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()

			_examplesDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples")
			exampleDir := filepath.Join(_examplesDir, "sns")

			test_structure.RunTestStage(t, "bootstrap", func() {
				awsRegion := aws.GetRandomRegion(t, []string{}, []string{})
				uniqueId := random.UniqueId()
				queueName := fmt.Sprintf("test-topic-%s", uniqueId)

				test_structure.SaveString(t, exampleDir, KEY_SNS_TOPIC_NAME, queueName)
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
				topicName := test_structure.LoadString(t, exampleDir, KEY_SNS_TOPIC_NAME)
				terraformOptions := createTerratestOptionsForSNS(exampleDir, region, topicName, testCase.allowPublish, testCase.allowSubscribe)
				test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)

				terraform.InitAndApply(t, terraformOptions)
			})
		})
	}
}
