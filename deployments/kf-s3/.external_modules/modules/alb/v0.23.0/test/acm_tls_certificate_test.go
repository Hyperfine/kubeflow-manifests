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
	"github.com/stretchr/testify/assert"
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

			awsRegion := aws.GetRandomRegion(t, []string{"us-west-1", "us-west-2"}, nil)
			uniqueID := strings.ToLower(random.UniqueId())
			exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/acm-tls-certificate")

			// TODO: Create a test helper method for building nested cert maps
			domainName := fmt.Sprintf("acm-test-%s.%s", uniqueID, DefaultDomainNameForTest)

			acmTLSCertificatesMap := make(map[string]interface{})

			acmTLSCertificatesMap[domainName] = map[string]interface{}{
				"subject_alternative_names":  []string{},
				"create_verification_record": true,
				"verify_certificate":         true,
				"tags":                       map[string]bool{"run_destroy_check": testCase.destroyCheck},
				"hosted_zone_id":             DefaultHostedZoneIdForTest,
			}

			terraformOptions := &terraform.Options{
				TerraformDir: exampleDir,
				Vars: map[string]interface{}{
					"aws_region":           awsRegion,
					"alb_name":             fmt.Sprintf("alb-%s", uniqueID),
					"domain_name":          domainName,
					"hosted_zone_id":       DefaultHostedZoneIdForTest,
					"acm_tls_certificates": acmTLSCertificatesMap,
				},

				RetryableTerraformErrors: defaultRetryableErrors,
			}

			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)

			// Check we can talk to HTTPS against the ALB without issues. Since we haven't added any listener rules to the ALB,
			// it should return a 404 by default.
			outputDomainName := terraform.OutputRequired(t, terraformOptions, "certificate_domain_name")
			lbUrl := fmt.Sprintf("https://%s", outputDomainName)
			http_helper.HttpGetWithRetry(t, lbUrl, nil, 404, "", 20, 5*time.Second)
		})
	}
}

// Ensure that running plan with an empty certificate input
// schedules no resources for creation
func TestCreatingZeroCerts(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomRegion(t, RegionsWithGruntworkINACM, nil)

	exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/multiple-acm-tls-certificates")

	terraformOptions := &terraform.Options{
		TerraformDir: exampleDir,
		Vars: map[string]interface{}{
			"aws_region":           awsRegion,
			"acm_tls_certificates": make(map[string]interface{}),
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	output := terraform.InitAndApply(t, terraformOptions)

	resourceCount := terraform.GetResourceCount(t, output)
	// There will be one null resource created
	// but not a certificate
	assert.Equal(t, resourceCount.Add, 1)
	assert.Equal(t, resourceCount.Change, 0)
	assert.Equal(t, resourceCount.Destroy, 0)
}

// Verify that you can create a single certificate successfully
func TestCreatingSingleCert(t *testing.T) {
	t.Parallel()

	// You can uncomment the items below to skip specific test stages
	//os.Setenv("SKIP_configure", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_validate", "true")
	//os.Setenv("SKIP_destroy", "true")

	testFolder := "../examples/multiple-acm-tls-certificates"

	defer test_structure.RunTestStage(t, "destroy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "configure", func() {
		// For the us-west-1 and 2 regions, we have higher certificate issuance quotas
		// to assist with testing
		awsRegion := aws.GetRandomRegion(t, []string{"us-west-1", "us-west-2"}, nil)
		uniqueID := strings.ToLower(random.UniqueId())

		// TODO: Create method for building cert maps
		domainKeyName := fmt.Sprintf("mail-%s.%s", uniqueID, DefaultDomainNameForTest)
		SAN := fmt.Sprintf("smtp-%s.%s", uniqueID, DefaultDomainNameForTest)

		acmTLSCertificatesMap := make(map[string]interface{})

		acmTLSCertificatesMap[domainKeyName] = map[string]interface{}{
			"subject_alternative_names":  []string{SAN},
			"create_verification_record": false,
			"verify_certificate":         false,
			"hosted_zone_id":             DefaultDomainNameForTest,
		}

		exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/multiple-acm-tls-certificates")

		terraformOptions := &terraform.Options{
			TerraformDir: exampleDir,
			Vars: map[string]interface{}{
				"aws_region":           awsRegion,
				"acm_tls_certificates": acmTLSCertificatesMap,
			},
		}

		test_structure.SaveTerraformOptions(t, testFolder, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		output := terraform.InitAndApply(t, terraformOptions)
		test_structure.SaveString(t, testFolder, "apply-output", output)
	})

	test_structure.RunTestStage(t, "validate", func() {
		output := test_structure.LoadString(t, testFolder, "apply-output")
		resourceCount := terraform.GetResourceCount(t, output)
		assert.Equal(t, resourceCount.Add, 2)
		assert.Equal(t, resourceCount.Change, 0)
		assert.Equal(t, resourceCount.Destroy, 0)
	})
}

// Verifies that creating a cert with both:
// - create_verification_record
// - verify_certificate
// set to true will result in:
//
// One certificate request
// Two Route 53 records (one for the domain name and one for the SAN)
// One certificate verification action against both Route 53 records
func TestCreatingSingleVerifiedCertsPlan(t *testing.T) {
	t.Parallel()

	// For the us-west-1 and 2 regions, we have higher certificate issuance quotas
	// to assist with testing
	awsRegion := aws.GetRandomRegion(t, []string{"us-west-1", "us-west-2"}, nil)
	uniqueID := strings.ToLower(random.UniqueId())

	// TODO: Create method for building cert maps
	domainKeyName := fmt.Sprintf("mail-%s.%s", uniqueID, DefaultDomainNameForTest)
	SAN := fmt.Sprintf("smtp-%s.%s", uniqueID, DefaultDomainNameForTest)

	acmTLSCertificatesMap := make(map[string]interface{})

	acmTLSCertificatesMap[domainKeyName] = map[string]interface{}{
		"subject_alternative_names":  []string{SAN},
		"create_verification_record": true,
		"verify_certificate":         true,
		"hosted_zone_id":             DefaultHostedZoneIdForTest,
	}

	exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/multiple-acm-tls-certificates")

	terraformOptions := &terraform.Options{
		TerraformDir: exampleDir,
		Vars: map[string]interface{}{
			"aws_region":           awsRegion,
			"acm_tls_certificates": acmTLSCertificatesMap,
		},
	}

	output := terraform.InitAndPlan(t, terraformOptions)
	resourceCount := terraform.GetResourceCount(t, output)
	assert.Equal(t, resourceCount.Add, 5)
	assert.Equal(t, resourceCount.Change, 0)
	assert.Equal(t, resourceCount.Destroy, 0)

	// TODO: once this is working, do more rigorous testing on the
	// state of the created resources
}

// Verifies that creating a cert with both:
// - create_verification_record
// - verify_certificate
// set to true will result in:
//
// One certificate request
// Two Route 53 records (one for the domain name and one for the SAN)
// One certificate verification action against both Route 53 records
//
func TestCreatingVerifiedCertsPlan(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_setup", "true")
	//os.Setenv("SKIP_apply_and_verify", "true")

	exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/multiple-acm-tls-certificates")

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomRegion(t, RegionsWithGruntworkINACM, nil)
		uniqueID := strings.ToLower(random.UniqueId())

		// TODO: Create method for building cert maps
		domainKeyName := fmt.Sprintf("mail-%s.%s", uniqueID, DefaultDomainNameForTest)
		domainKeyName2 := fmt.Sprintf("extra-%s.%s", uniqueID, DefaultDomainNameForTest)
		SAN := fmt.Sprintf("smtp-%s.%s", uniqueID, DefaultDomainNameForTest)

		acmTLSCertificatesMap := make(map[string]interface{})

		acmTLSCertificatesMap[domainKeyName] = map[string]interface{}{
			"subject_alternative_names":  []string{SAN},
			"create_verification_record": true,
			"verify_certificate":         true,
			"hosted_zone_id":             DefaultHostedZoneIdForTest,
		}

		// The boolean keys for this certificate are intentionally strings
		// to test the functionality in our module that accounts for the possibility
		// of the user doing exactly this
		acmTLSCertificatesMap[domainKeyName2] = map[string]interface{}{
			"subject_alternative_names":  []string{},
			"create_verification_record": "true",
			"verify_certificate":         "true",
			"hosted_zone_id":             DefaultHostedZoneIdForTest,
		}

		terraformOptions := &terraform.Options{
			TerraformDir: exampleDir,
			Vars: map[string]interface{}{
				"aws_region":           awsRegion,
				"acm_tls_certificates": acmTLSCertificatesMap,
			},
		}

		test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "plan_and_verify", func() {

		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)

		output := terraform.InitAndPlan(t, terraformOptions)
		resourceCount := terraform.GetResourceCount(t, output)
		assert.Equal(t, resourceCount.Add, 8)
		assert.Equal(t, resourceCount.Change, 0)
		assert.Equal(t, resourceCount.Destroy, 0)
	})

}

// Verifies that the default variables for create_verification_record
// and verify_certificate override the absence of the associated
// attributes on the certificate inputs themselves. Because both:
//
// - var.default_verify_certificate
// - var.default_create_verification_record
//
// default to true, passing a certificate input that specifies neither
// the verify_certficate or create_verification_record attributes
// should still result in a plan for a certificate verification and its
// required DNS records
func TestDefaultVerifyCertificateVars(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_setup", "true")
	//os.Setenv("SKIP_plan_and_verify", "true")

	exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/multiple-acm-tls-certificates")

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomRegion(t, RegionsWithGruntworkINACM, nil)
		uniqueID := strings.ToLower(random.UniqueId())

		domainKeyName := fmt.Sprintf("mail-%s.%s", uniqueID, DefaultDomainNameForTest)
		SAN := fmt.Sprintf("smtp-%s.%s", uniqueID, DefaultDomainNameForTest)

		acmTLSCertificatesMap := make(map[string]interface{})

		acmTLSCertificatesMap[domainKeyName] = map[string]interface{}{
			"subject_alternative_names": []string{SAN},
			// This certificate input is intentionally missing the create_verification_record attribute
			// This certificate input is intentionally missing the verify_certificate attribute
			"hosted_zone_id": DefaultHostedZoneIdForTest,
		}

		terraformOptions := &terraform.Options{
			TerraformDir: exampleDir,
			Vars: map[string]interface{}{
				"aws_region": awsRegion,
				// These two default vars default to true, but we nevertheless test that you can
				// successfully pass them into the module as well
				"default_verify_certificate":         true,
				"default_create_verification_record": true,
				"acm_tls_certificates":               acmTLSCertificatesMap,
			},
		}

		test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "plan_and_verify", func() {

		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)

		output := terraform.InitAndPlan(t, terraformOptions)
		resourceCount := terraform.GetResourceCount(t, output)
		assert.Equal(t, resourceCount.Add, 5)
		assert.Equal(t, resourceCount.Change, 0)
		assert.Equal(t, resourceCount.Destroy, 0)
	})
}

// Verifies that the default variables for create_verification_record
// and verify_certificate override the absence of the associated
// attributes on the certificate inputs themselves. When setting both:
//
// - var.default_verify_certificate
// - var.default_create_verification_record
//
// to false, neither the certificate verification nor any of its required
// DNS records should appear in the resulting plan
func TestDefaultVerifyCertificateVarsFalse(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_setup", "true")
	//os.Setenv("SKIP_plan_and_verify", "true")

	exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/multiple-acm-tls-certificates")

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomRegion(t, RegionsWithGruntworkINACM, nil)
		uniqueID := strings.ToLower(random.UniqueId())

		domainKeyName := fmt.Sprintf("mail-%s.%s", uniqueID, DefaultDomainNameForTest)
		SAN := fmt.Sprintf("smtp-%s.%s", uniqueID, DefaultDomainNameForTest)

		acmTLSCertificatesMap := make(map[string]interface{})

		acmTLSCertificatesMap[domainKeyName] = map[string]interface{}{
			"subject_alternative_names": []string{SAN},
			// This certificate input is intentionally missing the create_verification_record attribute
			// This certificate input is intentionally missing the verify_certificate attribute
			"hosted_zone_id": DefaultHostedZoneIdForTest,
		}

		terraformOptions := &terraform.Options{
			TerraformDir: exampleDir,
			Vars: map[string]interface{}{
				"aws_region": awsRegion,
				// Test that setting the default vars for certificate verification to false result in no
				// verification resources (when the certificate input also does not specify their values)
				"default_verify_certificate":         false,
				"default_create_verification_record": false,
				"acm_tls_certificates":               acmTLSCertificatesMap,
			},
		}

		test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "plan_and_verify", func() {

		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)

		output := terraform.InitAndPlan(t, terraformOptions)
		resourceCount := terraform.GetResourceCount(t, output)
		assert.Equal(t, resourceCount.Add, 2)
		assert.Equal(t, resourceCount.Change, 0)
		assert.Equal(t, resourceCount.Destroy, 0)
	})
}

// Verifies that the certificate input attributes, when set, override the default vars:
//
// - var.default_verify_certificate
// - var.default_create_verification_record
//
// In other words - if the certificate inputs themselves set both:
//
// - create_verification_record
// - verify_certificate
//
// to false, then setting the default vars to true will have no effect, and neither a
// certificate verification nor any of its required DNS validation records will be created
func TestCertInputTakesPrecedence(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_setup", "true")
	//os.Setenv("SKIP_plan_and_verify", "true")

	exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/multiple-acm-tls-certificates")

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomRegion(t, RegionsWithGruntworkINACM, nil)
		uniqueID := strings.ToLower(random.UniqueId())

		domainKeyName := fmt.Sprintf("mail-%s.%s", uniqueID, DefaultDomainNameForTest)
		SAN := fmt.Sprintf("smtp-%s.%s", uniqueID, DefaultDomainNameForTest)

		acmTLSCertificatesMap := make(map[string]interface{})

		acmTLSCertificatesMap[domainKeyName] = map[string]interface{}{
			"subject_alternative_names":  []string{SAN},
			"verify_certificate":         false,
			"create_verification_record": false,
			"hosted_zone_id":             DefaultHostedZoneIdForTest,
		}

		terraformOptions := &terraform.Options{
			TerraformDir: exampleDir,
			Vars: map[string]interface{}{
				"aws_region":                         awsRegion,
				"default_verify_certificate":         true,
				"default_create_verification_record": true,
				"acm_tls_certificates":               acmTLSCertificatesMap,
			},
		}

		test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "plan_and_verify", func() {

		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)

		output := terraform.InitAndPlan(t, terraformOptions)
		resourceCount := terraform.GetResourceCount(t, output)
		assert.Equal(t, resourceCount.Add, 2)
		assert.Equal(t, resourceCount.Change, 0)
		assert.Equal(t, resourceCount.Destroy, 0)
	})
}
