package test

import (
	"fmt"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/stretchr/testify/require"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestLbListenerRules(t *testing.T) {
	t.Parallel()

	// Uncomment the items below to skip certain parts of the test
	//os.Setenv("TERRATEST_REGION", "eu-central-1")
	//os.Setenv("SKIP_setup", "true")
	//os.Setenv("SKIP_deploy_terraform", "true")
	//os.Setenv("SKIP_validate_rules", "true")
	//os.Setenv("SKIP_cleanup", "true")

	testFolder := "../examples/lb-listener-rules"

	defer test_structure.RunTestStage(t, "cleanup", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomRegion(t, nil, nil)

		test_structure.SaveString(t, testFolder, "region", awsRegion)

		name := fmt.Sprintf("alb-%s", random.UniqueId())

		terraformOptions := &terraform.Options{
			TerraformDir: testFolder,
			Vars: map[string]interface{}{
				"aws_region": awsRegion,
				"alb_name":   name,
			},
		}

		test_structure.SaveString(t, testFolder, "lbName", name)
		test_structure.SaveTerraformOptions(t, testFolder, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_terraform", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)

		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate_rules", func() {

		lbName := test_structure.LoadString(t, testFolder, "lbName")
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		deployedLbName := terraform.OutputRequired(t, terraformOptions, "alb_name")
		require.Equal(t, deployedLbName, lbName)

		deployedLbDnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
		lbUrl := fmt.Sprintf("http://%s", deployedLbDnsName)

		http_helper.HttpGetWithRetry(t, lbUrl, nil, 200, "Hello, this is root", 20, 5*time.Second)

		responseJson := fmt.Sprintf("%s/?response-type=json", lbUrl)
		http_helper.HttpGetWithRetry(t, responseJson, nil, 200, "{\"hello\": \"grunt\"}", 20, 5*time.Second)

		redirectToFoo := fmt.Sprintf("%s/bar/", lbUrl)
		http_helper.HttpGetWithRetry(t, redirectToFoo, nil, 200, "Hello, this is foo", 20, 5*time.Second)
	})
}
