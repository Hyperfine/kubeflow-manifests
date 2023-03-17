package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestEcsAlarms(t *testing.T) {
	t.Parallel()

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
		uniqueID := strings.ToLower(random.UniqueId())
		vpc := aws.GetDefaultVpc(t, awsRegion)

		terraformOptions := &terraform.Options{
			// The path to where your Terraform code is located
			TerraformDir: fmt.Sprintf("%s/ecs-alarms", examplesDir),
			Vars: map[string]interface{}{
				"aws_region":           awsRegion,
				"aws_account_id":       aws.GetAccountId(t),
				"cluster_name":         "TestEcsAlarmsCluster" + uniqueID,
				"service_name":         "TestEcsAlarmsService" + uniqueID,
				"cluster_instance_ami": aws.GetEcsOptimizedAmazonLinuxAmi(t, awsRegion),
				"vpc_id":               vpc.Id,
				"subnet_ids":           getDefaultVPCSubnetIDs(t, awsRegion),
				"environment_name":     "test",
			},

			RetryableTerraformErrors: map[string]string{
				// On terraform 0.12, `terraform destroy` for ECS clusters started to fail intermittently with
				// ClusterContainsContainerInstancesException. The reason is unknown why this is more frequent on tf12 than
				// tf11. A second `destroy` call usually works successfully. See
				// https://github.com/terraform-providers/terraform-provider-aws/issues/4852 for more details.
				".*ClusterContainsContainerInstancesException.*": "Failed to destroy the cluster due to lingering services.",
			},
			MaxRetries:         3,
			TimeBetweenRetries: 5 * time.Second,

			// We set TF_WARN_OUTPUT_ERRORS=1 when running `terraform`, because a repeated destroy fails due to inaccessible
			// resources in the output computation. See above for why we might end up calling `destroy` multiple times.
			EnvVars: map[string]string{
				"TF_WARN_OUTPUT_ERRORS": "1",
			},
		}

		terraformOptions.RetryableTerraformErrors = map[string]string{
			"Unable to assume role and validate the listeners configured on your load balancer":                       "An eventual consistency bug in Terraform related to IAM role propagation and ECS. More details here: https://github.com/hashicorp/terraform/issues/4375.",
			"Error creating launch configuration: ValidationError: You are not authorized to perform this operation.": "An mysterious, intermittent error that has been happening with launch configurations recently. More details here: https://github.com/hashicorp/terraform/issues/7198",
			"does not have attribute 'id' for variable 'aws_security_group.":                                          "An mysterious, intermittent error that has been happening with launch configurations recently. More details here: https://github.com/hashicorp/terraform/issues/2583",
			"Invalid IamInstanceProfile": "An intermittent error that happens with launch configurations. More details here: https://github.com/hashicorp/terraform/issues/2136",
		}

		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy_to_aws", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.InitAndApply(t, terraformOptions)
	})

	// TODO: figure out a way to 1) make CPU and memory usage high in the ECS Cluster,
	// 2) subscribe to the SNS topic, and 3) check that you get notifications for the alarms.
}
