package test

import (
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/retry"
)

func getCurrentBranchName(t *testing.T) string {
	cmd := exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD")
	bytes, err := cmd.Output()
	if err != nil {
		t.Fatalf("Failed to determine current branch name due to error: %s\n", err.Error())
	}
	return strings.TrimSpace(string(bytes))
}

func getSubnetIds(vpc aws.Vpc) []string {
	subnetIds := []string{}

	for _, subnet := range vpc.Subnets {
		subnetIds = append(subnetIds, subnet.Id)
	}

	return subnetIds
}

func getDefaultVPCSubnetIDs(t *testing.T, awsRegion string) []string {
	vpc := aws.GetDefaultVpc(t, awsRegion)
	subnets := aws.GetSubnetsForVpc(t, vpc.Id, awsRegion)
	subnetIDs := []string{}
	for _, subnet := range subnets {
		subnetIDs = append(subnetIDs, subnet.Id)
	}
	return subnetIDs
}

func doWithRetryAndTimeout(t *testing.T, action func() (string, error), actionDescription string, maxRetries int, sleepBetweenRetries time.Duration, maxTimeoutPerRetry time.Duration) (string, error) {
	return retry.DoWithRetryE(t, actionDescription, maxRetries, sleepBetweenRetries, func() (string, error) {
		return retry.DoWithTimeoutE(t, actionDescription, maxTimeoutPerRetry, action)
	})
}
