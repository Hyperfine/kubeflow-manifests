package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

// TODO: make some requests to the ELB, download its access logs from S3, and make sure the requests show up in
// those log files
func TestElbAccessLogs(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
		uniqueID := strings.ToLower(random.UniqueId())
		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: fmt.Sprintf("%s/load-balancer-access-logs/elb", examplesDir),
			Vars: map[string]interface{}{
				"aws_region":     awsRegion,
				"aws_account_id": aws.GetAccountId(t),
				"name":           "TestElbAccessLogs" + uniqueID,
				"subnet_ids":     getDefaultVPCSubnetIDs(t, awsRegion),
			},
		})

		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_to_aws", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.InitAndApply(t, terraformOptions)
	})
}

// TODO: make some requests to the ALB, download its access logs from S3, and make sure the requests show up in
// those log files
func TestAlbAccessLogs(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
		uniqueID := strings.ToLower(random.UniqueId())

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: fmt.Sprintf("%s/load-balancer-access-logs/alb", examplesDir),
			Vars: map[string]interface{}{
				"aws_region":     awsRegion,
				"aws_account_id": aws.GetAccountId(t),
				"name":           "TestAlbAccessLogs" + uniqueID,
				"subnet_ids":     getDefaultVPCSubnetIDs(t, awsRegion),
			},
		})

		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_to_aws", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.InitAndApply(t, terraformOptions)
	})
}

// TODO: make some requests to the NLB, download its access logs from S3, and make sure the requests show up in
// those log files
func TestNlbAccessLogs(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
		uniqueID := strings.ToLower(random.UniqueId())

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: fmt.Sprintf("%s/load-balancer-access-logs/nlb", examplesDir),
			Vars: map[string]interface{}{
				"aws_region":     awsRegion,
				"aws_account_id": aws.GetAccountId(t),
				"name":           "TestNlbAccessLogs" + uniqueID,
				"subnet_ids":     getDefaultVPCSubnetIDs(t, awsRegion),
			},
		})

		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_to_aws", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.InitAndApply(t, terraformOptions)
	})
}
