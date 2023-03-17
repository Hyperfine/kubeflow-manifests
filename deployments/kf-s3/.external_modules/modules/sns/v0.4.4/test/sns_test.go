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
	"github.com/stretchr/testify/assert"
)

const serviceName1 = "events.amazonaws.com"
const serviceName2 = "rds.amazonaws.com"

func TestSNS(t *testing.T) {
	t.Parallel()

	userArn := aws.GetIamCurrentUserArn(t)

	var testcases = []struct {
		testName       string
		allowPublish   []string
		allowService   []string
		allowSubscribe []string
	}{
		{
			"AllowAll",
			[]string{userArn},
			[]string{serviceName1, serviceName2},
			[]string{userArn},
		},
		{
			"AllowPublish",
			[]string{userArn},
			[]string{},
			[]string{},
		},
		{
			"AllowService",
			[]string{},
			[]string{serviceName1, serviceName2},
			[]string{},
		},
		{
			"AllowSub",
			[]string{},
			[]string{},
			[]string{userArn},
		},
		{
			"AllowNone",
			[]string{},
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
				terraformOptions := createTerratestOptionsForSNS(exampleDir, region, topicName, testCase.allowPublish, testCase.allowService, testCase.allowSubscribe)
				test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)

				terraform.InitAndApply(t, terraformOptions)

				topicPolicyOutput := terraform.OutputRequired(t, terraformOptions, "topic_policy")

				if len(testCase.allowPublish) > 0 || len(testCase.allowSubscribe) > 0 {
					assert.Contains(t, topicPolicyOutput, userArn)
					if len(testCase.allowService) > 0 {
						assert.Contains(t, topicPolicyOutput, serviceName1)
						assert.Contains(t, topicPolicyOutput, serviceName2)
					}
				} else if len(testCase.allowService) > 0 {
					assert.Contains(t, topicPolicyOutput, serviceName1)
					assert.Contains(t, topicPolicyOutput, serviceName2)
				} else {
					assert.NotContains(t, topicPolicyOutput, userArn)
					assert.Contains(t, topicPolicyOutput, "__default_policy_ID")
				}

				if len(testCase.allowPublish) > 0 || len(testCase.allowService) > 0 {
					assert.Contains(t, topicPolicyOutput, "sns:Publish")
				} else if len(testCase.allowSubscribe) > 0 {
					assert.Contains(t, topicPolicyOutput, "sns:Subscribe")
				}

			})
		})
	}
}

// Make sure the module can apply and destroy without errors with create_resources set to false
func TestSNSNoResources(t *testing.T) {
	t.Parallel()

	snsExampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/sns")
	awsRegion := aws.GetRandomRegion(t, nil, nil)
	topicName := fmt.Sprintf("test-topic-%s", random.UniqueId())

	terratestOptions := createTerratestOptionsForSNS(snsExampleDir, awsRegion, topicName, nil, nil, nil)
	terratestOptions.Vars["create_resources"] = false

	defer terraform.Destroy(t, terratestOptions)
	terraform.InitAndApply(t, terratestOptions)
}
