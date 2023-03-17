package test

import (
	"fmt"
	"strings"
	"testing"

	awsgo "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/rds"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/require"
)

// RDS only allows lowercase alphanumeric characters and hyphens. The name must also start with a letter.
func formatRdsName(name string) string {
	return "test" + strings.ToLower(name)
}

func deleteFinalSnapshot(t *testing.T, awsRegion string, dbInstanceName string) {
	rdsClient := aws.NewRdsClient(t, awsRegion)

	snapshotName := fmt.Sprintf("%s-final-snapshot", dbInstanceName)
	request := &rds.DeleteDBClusterSnapshotInput{DBClusterSnapshotIdentifier: awsgo.String(snapshotName)}
	_, err := rdsClient.DeleteDBClusterSnapshot(request)
	require.NoError(t, err)
}
