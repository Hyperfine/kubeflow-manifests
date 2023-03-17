package test

import (
	"fmt"
	"path/filepath"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
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

var defaultRetryableErrors = map[string]string{
	"Unable to assume role and validate the listeners configured on your load balancer":                       "An eventual consistency bug in Terraform related to IAM role propagation and ECS. More details here: https://github.com/hashicorp/terraform/issues/4375.",
	"Error creating launch configuration: ValidationError: You are not authorized to perform this operation.": "An mysterious, intermittent error that has been happening with launch configurations recently. More details here: https://github.com/hashicorp/terraform/issues/7198",
	"does not have attribute 'id' for variable 'aws_security_group.":                                          "An mysterious, intermittent error that has been happening with launch configurations recently. More details here: https://github.com/hashicorp/terraform/issues/2583",
}

func TestAlb(t *testing.T) {
	t.Parallel()

	// zoneName := "gruntwork-sandbox.com" // Use this with Sandbox
	zoneName := "gruntwork.in" // Use this with PhxDevops

	var testcases = []struct {
		testName     string
		templatePath string
		withLogs     bool
	}{
		{
			"TestCreateAlb",
			"../examples/alb",
			false,
		},
		{
			"TestCreateAlbWithLogs",
			"../examples/alb-with-logs",
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

				terraformOptions := &terraform.Options{
					TerraformDir: testCase.templatePath,
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
					terraformOptions.Vars["route53_zone_name"] = zoneName
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
