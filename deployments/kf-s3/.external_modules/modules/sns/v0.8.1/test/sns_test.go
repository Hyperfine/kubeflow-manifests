package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

const SNS_PATH = "examples/sns"
const serviceName1 = "events.amazonaws.com"
const serviceName2 = "rds.amazonaws.com"

type testCase struct {
	Name           string
	AllowPublish   []string
	AllowService   []string
	AllowSubscribe []string
}

func TestSNS(t *testing.T) {
	t.Parallel()

	// os.Setenv("SKIP_bootstrap", "true")
	// os.Setenv("SKIP_deploy", "true")
	// os.Setenv("SKIP_teardown", "true")

	userArn := aws.GetIamCurrentUserArn(t)

	var testcases = []testCase{
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

		t.Run(testCase.Name, func(t *testing.T) {
			t.Parallel()

			exampleDir := test_structure.CopyTerraformFolderToTemp(t, REPO_ROOT, SNS_PATH)

			test_structure.RunTestStage(t, "bootstrap", func() {
				awsRegion := aws.GetRandomRegion(t, nil, FORBIDDEN_REGIONS)
				uniqueId := random.UniqueId()
				topicName := fmt.Sprintf("test-topic-%s", uniqueId)
				terraformOptions := createTerratestOptionsForSNS(exampleDir, awsRegion, topicName, testCase.AllowPublish, testCase.AllowService, testCase.AllowSubscribe)
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

				topicPolicyOutput := terraform.OutputRequired(t, terraformOptions, "topic_policy")

				if len(testCase.AllowPublish) > 0 || len(testCase.AllowSubscribe) > 0 {
					assert.Contains(t, topicPolicyOutput, userArn)
					if len(testCase.AllowService) > 0 {
						assert.Contains(t, topicPolicyOutput, serviceName1)
						assert.Contains(t, topicPolicyOutput, serviceName2)
					}
				} else if len(testCase.AllowService) > 0 {
					assert.Contains(t, topicPolicyOutput, serviceName1)
					assert.Contains(t, topicPolicyOutput, serviceName2)
				} else {
					assert.NotContains(t, topicPolicyOutput, userArn)
					assert.Contains(t, topicPolicyOutput, "__default_policy_ID")
				}

				if len(testCase.AllowPublish) > 0 || len(testCase.AllowService) > 0 {
					assert.Contains(t, topicPolicyOutput, "sns:Publish")
				} else if len(testCase.AllowSubscribe) > 0 {
					assert.Contains(t, topicPolicyOutput, "sns:Subscribe")
				}

			})
		})
	}
}

// Make sure the module can apply and destroy without errors with create_resources set to false
func TestSNSNoResources(t *testing.T) {
	t.Parallel()

	snsExampleDir := test_structure.CopyTerraformFolderToTemp(t, REPO_ROOT, SNS_PATH)
	awsRegion := aws.GetRandomRegion(t, nil, FORBIDDEN_REGIONS)
	topicName := fmt.Sprintf("test-topic-%s", random.UniqueId())

	terratestOptions := createTerratestOptionsForSNS(snsExampleDir, awsRegion, topicName, nil, nil, nil)
	terratestOptions.Vars["create_resources"] = false

	defer terraform.Destroy(t, terratestOptions)
	terraform.InitAndApply(t, terratestOptions)
}
