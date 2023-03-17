package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func CreateBaseTerraformOptions(t *testing.T, terraformDir string, awsRegion string) *terraform.Options {
	return &terraform.Options{
		TerraformDir:             terraformDir,
		RetryableTerraformErrors: retryableTerraformErrors,
		MaxRetries:               2,
		TimeBetweenRetries:       5 * time.Second,
		Vars: map[string]interface{}{
			"aws_region": awsRegion,
		},
	}
}
