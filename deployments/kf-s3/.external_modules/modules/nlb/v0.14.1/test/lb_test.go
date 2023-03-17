package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

var defaultExcludedRegions = []string{"ap-southeast-1", "sa-east-1"}
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
		lbNameVar    string
		lbType       string
		withLogs     bool
	}{
		{
			"TestCreateAlb",
			"../examples/alb",
			"alb_name",
			"alb",
			false,
		},
		{
			"TestCreateAlbWithLogs",
			"../examples/alb-with-logs",
			"alb_name",
			"alb",
			true,
		},
		{
			"TestCreateNlb",
			"../examples/nlb",
			"nlb_name",
			"nlb",
			false,
		},
		{
			"TestCreateNlbWithSubnetMapping",
			"../examples/nlb-with-subnet-mappings",
			"nlb_name",
			"nlb",
			false,
		},
		{
			"TestCreateNlbWithLogs",
			"../examples/nlb-with-logs",
			"nlb_name",
			"nlb",
			true,
		},
	}

	for _, testCase := range testcases {
		// The following is necessary to make sure testCase's values don't
		// get updated due to concurrency within the scope of t.Run(..) below
		testCase := testCase

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()

			awsRegion := aws.GetRandomStableRegion(t, nil, defaultExcludedRegions)
			lbName := fmt.Sprintf("%s-%s", testCase.lbType, random.UniqueId())

			terraformOptions := &terraform.Options{
				TerraformDir: testCase.templatePath,
				Vars: map[string]interface{}{
					"aws_region":       awsRegion,
					testCase.lbNameVar: lbName,
					"environment_name": "terratest",
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

			defer terraform.Destroy(t, terraformOptions)

			terraform.InitAndApply(t, terraformOptions)

			deployedLbName := terraform.OutputRequired(t, terraformOptions, testCase.lbNameVar)

			if deployedLbName != lbName {
				t.Fatalf("Terraform output value for %s should equal %s, but got %s\n", testCase.lbNameVar, lbName, deployedLbName)
			}

			// Do one extra check for the ALB: make sure that its default action is to return fixed response of a blank
			// 404 page. The NLB does not support fixed responses, so we don't validate that behavior for it.
			if testCase.lbType == "alb" {
				deployedLbDnsName := terraform.Output(t, terraformOptions, fmt.Sprintf("%s_dns_name", testCase.lbType))
				lbUrl := fmt.Sprintf("http://%s", deployedLbDnsName)
				http_helper.HttpGetWithRetry(t, lbUrl, 404, "", 20, 5*time.Second)
			}
		})
	}
}
