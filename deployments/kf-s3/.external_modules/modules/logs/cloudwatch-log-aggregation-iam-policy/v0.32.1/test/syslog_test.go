package test

import (
	"fmt"
	"path/filepath"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/packer"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

// The test for the syslog module merely builds AMIs using Packer to ensure the script runs to completion without
// errors. TODO: syslog settings at test time to check log rotation and rate limiting work as expected.
func TestSyslog(t *testing.T) {
	var testcases = []struct {
		testName      string
		osName        string
		sleepDuration int
	}{
		{
			"TestSyslogUbuntu",
			"ubuntu",
			0,
		},
		{
			"TestSyslogUbuntu1804",
			"ubuntu-18",
			3,
		},
		{
			"TestSyslogAmazonLinux1",
			"amazon-linux",
			6,
		},
		{
			"TestSyslogAmazonLinux2",
			"amazon-linux-2",
			9,
		},
		{
			"TestSyslogCentOS",
			"centos",
			12,
		},
	}

	for _, testCase := range testcases {
		// The following is necessary to make sure testCase's values don't
		// get updated due to concurrency within the scope of t.Run(..) below
		testCase := testCase

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()

			// Create a directory path that won't conflict for storing test stage data
			workingDir := filepath.Join(".", "stages", t.Name())

			// This is terrible - but attempt to stagger the test cases to
			// avoid a concurrency issue
			time.Sleep(time.Duration(testCase.sleepDuration) * time.Second)

			examplesDir := test_structure.CopyTerraformFolderToTemp(t, "..", "/examples")
			amiDir := fmt.Sprintf("%s/syslog", examplesDir)
			templatePath := fmt.Sprintf("%s/%s", amiDir, "syslog-example.json")

			defer test_structure.RunTestStage(t, "teardown", func() {
				awsRegion := test_structure.LoadString(t, workingDir, "awsRegion")
				amiID := test_structure.LoadArtifactID(t, workingDir)
				aws.DeleteAmiAndAllSnapshots(t, awsRegion, amiID)
			})

			test_structure.RunTestStage(t, "setup_ami", func() {
				awsRegion := aws.GetRandomStableRegion(t, []string{}, []string{})
				test_structure.SaveString(t, workingDir, "awsRegion", awsRegion)

				// We run automated tests against this example code in many regions, and some AZs in some regions don't have certain
				// instance types. Therefore, we use this function to pick an instance type that's available in all AZs in the
				// current region.
				instanceType := aws.GetRecommendedInstanceType(t, awsRegion, []string{"t3.micro", "t2.micro"})

				options := &packer.Options{
					Template: templatePath,
					Only:     fmt.Sprintf("%s-build", testCase.osName),
					Vars: map[string]string{
						"aws_region":                  awsRegion,
						"module_aws_montoring_branch": getCurrentBranchName(t),
						"instance_type":               instanceType,
					},
				}

				amiID := packer.BuildAmi(t, options)
				test_structure.SaveArtifactID(t, workingDir, amiID)
			})
		})
	}
}
