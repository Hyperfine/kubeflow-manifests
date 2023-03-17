package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func TestLambdaRdsSnapshotDisable(t *testing.T) {
	t.Parallel()

	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/lambda-rds-snapshot")
	uniqueId := random.UniqueId()
	region := getAuroraRegion(t)
	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"aws_region":          region,
			"name":                formatRdsName(uniqueId),
			"master_username":     "username",
			"master_password":     "password",
			"external_account_id": getExternalAccountId(),
			"schedule_expression": "rate(5 hours)",
			"max_snapshots":       0,
			"allow_delete_all":    true,
			"enable_snapshot":     false,
		},
	}
	setRetryParametersOnTerraformOptions(t, terraformOptions)

	planOut := terraform.InitAndPlan(t, terraformOptions)
	resourceCounts := terraform.GetResourceCount(t, planOut)

	// The resources we are expecting to be created are:
	//
	// + resource "aws_db_subnet_group" "cluster" {
	// + resource "aws_rds_cluster" "cluster_without_encryption" {
	// + resource "aws_rds_cluster_instance" "cluster_instances" {
	// + resource "aws_security_group" "cluster" {
	// + resource "aws_security_group_rule" "allow_connections_from_cidr_blocks" {
	// + resource "null_resource" "dependency_getter" {
	// + resource "aws_db_instance" "primary_without_encryption" {
	// + resource "aws_db_subnet_group" "db" {
	// + resource "aws_security_group" "db" {
	// + resource "aws_security_group_rule" "allow_connections_from_cidr_blocks" {

	assert.Equal(t, resourceCounts.Add, 10)
	assert.Equal(t, resourceCounts.Change, 0)
	assert.Equal(t, resourceCounts.Destroy, 0)

	terraformOptions.Vars["enable_snapshot"] = true
	enabledPlanOut := terraform.InitAndPlan(t, terraformOptions)
	enabledResourceCounts := terraform.GetResourceCount(t, enabledPlanOut)
	assert.True(t, enabledResourceCounts.Add > resourceCounts.Add)
}
