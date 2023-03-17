package test

import (
	"fmt"
	"testing"
	"time"

	aws_sdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/backup"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"

	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestBackupRecoveryPointsCreated(t *testing.T) {

	t.Parallel()

	testFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/vault-recovery-points")

	defer test_structure.RunTestStage(t, "cleanup", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {

		awsRegion := aws.GetRandomRegion(t, nil, nil)
		test_structure.SaveString(t, testFolder, "region", awsRegion)
		name := random.UniqueId()
		serviceRoleName := fmt.Sprintf("%s-%s", name, "backup-service-role")
		test_structure.SaveString(t, testFolder, "serviceRoleName", serviceRoleName)

		terraformOptions := CreateBaseTerraformOptions(t, testFolder, awsRegion)
		terraformOptions.Vars["aws_region"] = awsRegion
		terraformOptions.Vars["backup_service_role_name"] = serviceRoleName
		terraformOptions.Vars["name"] = name
		test_structure.SaveTerraformOptions(t, testFolder, terraformOptions)
		test_structure.SaveString(t, testFolder, "name", name)

	})

	test_structure.RunTestStage(t, "deploy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, testFolder)
		name := test_structure.LoadString(t, testFolder, "name")

		terraform.InitAndApply(t, terraformOptions)

		iamRoleArn := terraform.OutputRequired(t, terraformOptions, "iam_role_arn")
		ec2InstanceArn := terraform.OutputRequired(t, terraformOptions, "ec2_instance_arn")

		vaultName := fmt.Sprintf("test-vault-recovery-points-%s", name)

		test_structure.SaveString(t, testFolder, "vaultName", vaultName)
		test_structure.SaveString(t, testFolder, "iamRoleArn", iamRoleArn)
		test_structure.SaveString(t, testFolder, "ec2InstanceArn", ec2InstanceArn)
	})

	test_structure.RunTestStage(t, "validate", func() {
		awsRegion := test_structure.LoadString(t, testFolder, "region")
		iamRoleArn := test_structure.LoadString(t, testFolder, "iamRoleArn")
		ec2InstanceArn := test_structure.LoadString(t, testFolder, "ec2InstanceArn")
		// Create a Backup job using the created backup vault and EC2 instance
		sess := session.Must(session.NewSession(&aws_sdk.Config{Region: aws_sdk.String(awsRegion)}))

		svc := backup.New(sess)

		vaultName := test_structure.LoadString(t, testFolder, "vaultName")

		startBackupJobInput := &backup.StartBackupJobInput{
			BackupVaultName: aws_sdk.String(vaultName),
			IamRoleArn:      aws_sdk.String(iamRoleArn),
			ResourceArn:     aws_sdk.String(ec2InstanceArn),
		}

		validationErr := startBackupJobInput.Validate()
		require.NoError(t, validationErr)
		if validationErr != nil {
			t.Logf("Error validating StartBackupJobInput: %+v\n", validationErr)
		}

		// Intentionally initiate a backup job using the target vault and IAM role created via Terraform.
		// We do this to avoid having to wait an undetermined amount of time for AWS Backup to commence a scheduled job.
		output, err := svc.StartBackupJob(startBackupJobInput)
		if err != nil {
			t.Logf("Error when attempting to start backup job: %+v\n", err)
		}
		require.NoError(t, err)
		t.Logf("output from starting job: %+v\n", output)

		// Poll the backup job status at regular intervals to determine when it is completed
		monitorBackupJob(t, output, svc)

		// Vaults that contain recovery points cannot be deleted, so we must first manually list
		// and delete all recovery points stored in the vault before terraform will destroy cleanly
		cleanupRecoveryPoints(t, vaultName, svc)
	})
}

// monitorBackupJob polls the started backub job until it is either completed, or the number of max attempts
// is exceeded
func monitorBackupJob(t *testing.T, jobOutput *backup.StartBackupJobOutput, svc *backup.Backup) {
	maxRetries := 20
	timeBetweenRetries := time.Minute * 1
	backupJobId := jobOutput.BackupJobId

	jobInput := &backup.DescribeBackupJobInput{
		BackupJobId: backupJobId,
	}

	for i := 0; i < maxRetries; i++ {
		jobOutput, err := svc.DescribeBackupJob(jobInput)
		if err != nil {
			t.Logf("Error describing backup job: %+v\n", jobOutput)
		}
		if aws_sdk.StringValue(jobOutput.State) == "COMPLETED" {
			t.Logf("Test backup job successfully completed at: %v\n", jobOutput.CompletionDate)
			return
		}
		t.Logf("Backup job state: %s. Sleeping for %s and retrying...", aws_sdk.StringValue(jobOutput.State), timeBetweenRetries)
		time.Sleep(timeBetweenRetries)
	}
	t.Logf("Test failed because test backup job did not reach status COMPLETED within configured timeout of time: %v between total tries: %v", timeBetweenRetries, maxRetries)
	t.Fail()
}

// cleanupRecoveryPoints will list any recovery points stored in the specified vault and delete them.
// This allows the vault to be subsequently destroyed without issue
func cleanupRecoveryPoints(t *testing.T, backupVaultName string, svc *backup.Backup) {

	listRecoveryPointsInput := &backup.ListRecoveryPointsByBackupVaultInput{
		BackupVaultName: aws_sdk.String(backupVaultName),
	}

	recoveryPointsOutput, err := svc.ListRecoveryPointsByBackupVault(listRecoveryPointsInput)
	if err != nil {
		t.Logf("Error listing recovery points for vault: %v\n", err)
	}

	//Ensure there was at least one recovery point in the target vault, otherwise we have a failure
	if len(recoveryPointsOutput.RecoveryPoints) < 1 {
		t.Log("Test backup vault expected to have at least 1 recovery point stored for end to end verification")
		t.Fail()
	}

	for _, recoveryPoint := range recoveryPointsOutput.RecoveryPoints {
		deleteInput := &backup.DeleteRecoveryPointInput{
			BackupVaultName:  aws_sdk.String(backupVaultName),
			RecoveryPointArn: recoveryPoint.RecoveryPointArn,
		}

		deleteOutput, deleteErr := svc.DeleteRecoveryPoint(deleteInput)
		if deleteErr != nil {
			t.Logf("Error deleting recovery point in test vault: %v\n", deleteErr)
		}
		t.Logf("Recovery point deletion output: %v\n", deleteOutput)
	}
}
