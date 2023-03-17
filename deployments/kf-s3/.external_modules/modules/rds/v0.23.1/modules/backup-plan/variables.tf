# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be set.
# ---------------------------------------------------------------------------------------------------------------------

variable "plans" {
  # Ideally, we would use a more strict type here but since we want to support required and optional values, and since
  # Terraform's type system only supports maps that have the same type for all values, we have to use the less useful
  # `any` type.

  type = any
  # Each key for each entry in the map is the name of the backup plan you want to create
  # Each entry in the map supports the following attributes:
  #
  # OPTIONAL (defaults to value of corresponding module input):
  # - advanced_backup_setting               [object] : An object that specifies backup options for each resource type. See the advanced_backup_setting for supported
  #                                                    attributes in this object.
  #
  #
  # - tags                                  [object] : Optional metadata you can assign to help organize plans you create
  #
  # REQUIRED
  #
  # - name                                  [string] : The display name of the backup plan
  #
  # - rule                                  [object] : An object that specifies the rule configuration for how and when the backup plan will be executed. See the rule setting
  #                                                    for supported attributes in this object
  #
  #
  # - selection                              [object] : An object that specifies which resources should be targeted for backup, and if they should be targeted
  #                                                     by tag or ARN
  #
  #   For advanced_backup_setting the following attibutes are supported:
  #
  #   backup_options - (Required) Specifies the backup option for a selected resource. This option is only available for Windows VSS backup jobs. Set to { WindowsVSS = "enabled" }
  #   to enable Windows VSS backup option and create a VSS Windows backup.
  #
  #   resource_type - (Required) The type of AWS resource to be backed up. For VSS Windows backups, the only supported resource type is Amazon EC2. Valid values: EC2
  #
  #   For rule the following attributes are supported:
  #
  #   rule_name - (Required) Specifies the display name of a backup
  #   target_vault_name - (Required) Specifies the name of the vault to associate this plan with
  #   schedule - (Optional) A CRON expression specifying when AWS Backup should initiate a backup job for this plan
  #   enable_continuous_backup - (Optional) Enable continuous backups for supported resources
  #   start_window - (Optional) The amount of time in minutes before beginning a backup
  #   completion_window - (Optional) The amount of time AWS Backup attempts a backup before canceling the job and returning an error
  #   lifecycle - (Optional) The lifecycle defines when a protected resource is transitioned to cold storage and when it expires
  #
  #   For lifecycle the following attributes are supported:
  #
  #   cold_storage_after - (Optional) Specifies the number of days after creation that a recovery point is moved to cold storage
  #   delete_after - (Optional) Specifies the number of days after creation that a recovery point is deleted. Must be 90 days greater than cold_storage_after
  #
  #   recovery_point_tags - (Optional) Metadata that you can assign to help organize the resources that you create
  #   copy_action - (Optional) Configuration block(s) with copy operation settings
  #
  #   For copy_action the following attributes are supported:
  #
  #   lifecycle - (Optional) The lifecycle defines when a protected resource is transitioned to cold storage and when it expires
  #
  #   For lifecycle the following attributes are supported:
  #
  #   cold_storage_after - (Optional) Specifies the number of days after creation that a recovery point is moved to cold storage
  #   delete_after - (Optional) Specifies the number of days after creation that a recovery point is deleted. Must be 90 days greater than cold_storage_after
  #
  #   For selection the following attributes are supported:
  #
  #   selection_tag - (Optional) An object configuring how to select resources via tags. You can EITHER use a selection_tag OR resources (below), or you can use BOTH in conjunction.
  #
  #   For selection_tag the following attributes are supported:
  #
  #   type - (Required) An operation, such as "StringEquals", that is applied to a key-value pair used to filter resources in a selection. For the full list of operations supported, see:   #                     https://docs.aws.amazon.com/aws-backup/latest/devguide/API_BackupSelection.html
  #   key - (Required) The key in a key-value pair
  #   value - (Required) The value in a key-value pair
  #
  #   resources - (Optional) A list of resource ARNs to select explicitly for backup
  #
  # Example:
  #
  # plans = {
  #  "my-ec2-backup-plan" = {
  #    advanced_backup_setting = {
  #      backup_options = {
  #        WindowsVSS = "enabled"
  #      }
  #      resource_type = "EC2"
  #    }
  #    rule = {
  #      rule_name         = "example-rule"
  #      target_vault_name = "vault-one"
  #      schedule          = "cron(0 12 * * ? *)"
  #      copy_action = {
  #        lifecycle = {
  #          cold_storage_after = 30
  #          delete_after       = 1
  #        }
  #      }
  #    }
  #    selection = {
  #      selection_tag = {
  #        type  = "STRINGEQUALS"
  #        key   = "Snapshot"
  #        value = "true"
  #      }
  #    }
  #    resources = ["arn:aws:lambda:us-east-1:816364267436:function:lambda-build-example"]
  #  }
  #}
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "backup_service_role_name" {
  type        = string
  description = "The name to use for the backup service role that is created and attached to backup plans."
  default     = "backup-service-role"
}
