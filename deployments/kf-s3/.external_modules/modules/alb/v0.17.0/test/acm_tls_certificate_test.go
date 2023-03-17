package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

// This is a Hosted Zone in the Gruntwork Phoenix DevOps AWS account
const DefaultDomainNameForTest = "gruntwork.in"
const DefaultHostedZoneIdForTest = "Z2AJ7S3R6G9UYJ"

func TestAcmTlsCertificate(t *testing.T) {
	t.Parallel()

	var testcases = []struct {
		testName     string
		destroyCheck bool
	}{
		{
			"WithoutDestroyCheck",
			false,
		},
		{
			"WithDestroyCheck",
			true,
		},
	}

	for _, testCase := range testcases {
		// The following is necessary to make sure testCase's values don't
		// get updated due to concurrency within the scope of t.Run(..) below
		testCase := testCase

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()

			awsRegion := aws.GetRandomRegion(t, RegionsWithGruntworkINACM, nil)
			uniqueId := strings.ToLower(random.UniqueId())
			exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/acm-tls-certificate")

			terraformOptions := &terraform.Options{
				TerraformDir: exampleDir,
				Vars: map[string]interface{}{
					"aws_region":        awsRegion,
					"alb_name":          fmt.Sprintf("alb-%s", uniqueId),
					"domain_name":       fmt.Sprintf("acm-test-%s.%s", uniqueId, DefaultDomainNameForTest),
					"hosted_zone_id":    DefaultHostedZoneIdForTest,
					"run_destroy_check": testCase.destroyCheck,
				},

				RetryableTerraformErrors: defaultRetryableErrors,
			}

			defer terraform.Destroy(t, terraformOptions)

			terraform.InitAndApply(t, terraformOptions)

			// Check we can talk to HTTPS against the ALB without issues. Since we haven't added any listener rules to the ALB,
			// it should return a 404 by default.
			domainName := terraform.OutputRequired(t, terraformOptions, "certificate_domain_name")
			lbUrl := fmt.Sprintf("https://%s", domainName)
			http_helper.HttpGetWithRetry(t, lbUrl, nil, 404, "", 20, 5*time.Second)
		})
	}
}
