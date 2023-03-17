package test

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var RegionsWithGruntworkINACM = []string{
	"us-east-1",
	"us-east-2",
	"us-west-1",
	"us-west-2",
	"eu-west-1",
	"eu-west-2",
}

var zoneNameEnvVarNotSetErr = "You must set the LB_TEST_ZONE_NAME env var to the name of a public hosted zone in your AWS account. Gruntwork employees should set this to gruntwork.in in Phx DevOps and gruntwork-sandbox.com in Sandbox. Customers should set this to a domain available in the current account that can host DNS records for testing purposes."

var defaultRetryableErrors = map[string]string{
	"Unable to assume role and validate the listeners configured on your load balancer":                       "An eventual consistency bug in Terraform related to IAM role propagation and ECS. More details here: https://github.com/hashicorp/terraform/issues/4375.",
	"Error creating launch configuration: ValidationError: You are not authorized to perform this operation.": "An mysterious, intermittent error that has been happening with launch configurations recently. More details here: https://github.com/hashicorp/terraform/issues/7198",
	"does not have attribute 'id' for variable 'aws_security_group.":                                          "An mysterious, intermittent error that has been happening with launch configurations recently. More details here: https://github.com/hashicorp/terraform/issues/2583",
}

func TestAlb(t *testing.T) {
	t.Parallel()

	var ZoneName string

	// If you want to run this test against your own AWS account's hosted zone, provide the name of your hosted zone
	// by setting the environment variable LB_TEST_ZONE_NAME
	if os.Getenv("LB_TEST_ZONE_NAME") == "" {
		t.Log(zoneNameEnvVarNotSetErr)
		t.Fail()
	} else {
		ZoneName = os.Getenv("LB_TEST_ZONE_NAME")
	}

	var testcases = []struct {
		testName     string
		templatePath string
		withLogs     bool
	}{
		{
			"TestCreateAlb",
			"examples/alb",
			false,
		},
		{
			"TestCreateAlbWithLogs",
			"examples/alb-with-logs",
			true,
		},
	}

	for _, testCase := range testcases {
		// The following is necessary to make sure testCase's values don't
		// get updated due to concurrency within the scope of t.Run(..) below
		testCase := testCase

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()

			// Uncomment any of the following to skip that section during the test
			//os.Setenv("SKIP_setup", "true")
			//os.Setenv("SKIP_deploy", "true")
			//os.Setenv("SKIP_validate", "true")
			//os.Setenv("SKIP_destroy", "true")

			workingDir := filepath.Join(".", "stages", t.Name())

			test_structure.RunTestStage(t, "setup", func() {
				awsRegion := aws.GetRandomRegion(t, RegionsWithGruntworkINACM, nil)
				lbName := fmt.Sprintf("alb-%s", random.UniqueId())

				terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", testCase.templatePath)

				terraformOptions := &terraform.Options{
					TerraformDir: terraformDir,
					Vars: map[string]interface{}{
						"aws_region": awsRegion,
						"alb_name":   lbName,
					},

					RetryableTerraformErrors: defaultRetryableErrors,
				}
				if testCase.withLogs {
					terraformOptions.Vars["force_destroy_access_logs_s3_bucket"] = true
				}
				if testCase.testName == "TestCreateAlb" {
					// The `alb` example requires a route53 zone
					terraformOptions.Vars["route53_zone_name"] = ZoneName
				}

				test_structure.SaveString(t, workingDir, "lbName", lbName)
				test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
			})

			defer test_structure.RunTestStage(t, "destroy", func() {
				terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
				terraform.Destroy(t, terraformOptions)
			})

			test_structure.RunTestStage(t, "deploy", func() {
				terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
				terraform.InitAndApply(t, terraformOptions)
			})

			test_structure.RunTestStage(t, "validate", func() {
				lbName := test_structure.LoadString(t, workingDir, "lbName")
				terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
				deployedLbName := terraform.OutputRequired(t, terraformOptions, "alb_name")
				require.Equal(t, deployedLbName, lbName)

				// Do one extra check for the ALB: make sure that its default action is to return fixed response of a blank
				// 404 page. The NLB does not support fixed responses, so we don't validate that behavior for it.
				deployedLbDnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
				lbUrl := fmt.Sprintf("http://%s", deployedLbDnsName)
				http_helper.HttpGetWithRetry(t, lbUrl, nil, 404, "", 40, 5*time.Second)
			})
		})
	}
}

// Ensures that Terraform variable validation catches any attempts to exceed the ALB's name's 32 character limit
func TestAlbNameLengthValidation(t *testing.T) {
	t.Parallel()

	// Uncomment the items below to skip certain parts of the test
	//os.Setenv("TERRATEST_REGION", "eu-west-1")
	//os.Setenv("SKIP_setup", "true")
	//os.Setenv("SKIP_deploy_terraform", "true")

	var ZoneName string
	// If you want to run this test against your own AWS account's hosted zone, provide the name of your hosted zone
	// by setting the environment variable LB_TEST_ZONE_NAME
	if os.Getenv("LB_TEST_ZONE_NAME") == "" {
		t.Log(zoneNameEnvVarNotSetErr)
		t.Fail()
	} else {
		ZoneName = os.Getenv("LB_TEST_ZONE_NAME")
	}

	testFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/alb")

	test_structure.RunTestStage(t, "setup", func() {
		// This test will never succeed in applying Terraform resources, so we can hard-code its region
		awsRegion := "us-east-1"

		// AWS imposes a 32 character limit on ALB names, so we'll intentionally exceed it here
		// to test that our variable validation catches the issue and returns an error
		lbName := fmt.Sprintf("alb-name-that-is-intentionally-too-long%s", random.UniqueId())
		terraformOptions := &terraform.Options{
			TerraformDir: testFolder,
			Vars: map[string]interface{}{
				"aws_region":        awsRegion,
				"alb_name":          lbName,
				"route53_zone_name": ZoneName,
			},
		}

		test_structure.SaveTerraformOptions(t, testFolder, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_terraform", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)

		_, err := terraform.InitAndApplyE(t, terraformOptions)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "Your alb_name must be 32 characters or less in length.")
	})
}
