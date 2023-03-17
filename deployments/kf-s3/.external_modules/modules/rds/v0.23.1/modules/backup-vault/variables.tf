variable "vaults" {
  # Ideally, we would use a more strict type here but since we want to support required and optional values, and since
  # Terraform's type system only supports maps that have the same type for all values, we have to use the less useful
  # `any` type.

  type = any
  # Each key for each entry in the map is the name of the name of the vault you want to create
  # Each entry in the map supports the following attributes:
  #
  # OPTIONAL (defaults to value of corresponding module input):
  # - kms_key_arn                           [string] : the ARN for the KMS key you want used to encrypt the recovery points stored in your vault
  # - enable_notifications                  [bool]   : Whether or not to create SNS topics and allow the vault to publish events to it
  # - events_to_listen_for                  [list(string}] : A list of AWS Backup vault events you want to listen for. If you do not pass this list, ALL events will be listened for.
  #
  # Example:
  # "vaults" = {
  #   "my-vault-one" = {
  #      kms_key_arn = "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  #      enable_notifications = true
  #      events_to_listen_for = ["BACKUP_JOB_STARTED", "COPY_JOB_FAILED", "RESTORE_JOB_COMPLETED"]
  # }
  # # Configure a vault using the default encryption key and no notifications:
  # "my-vault-two = {}
  #}
}

variable "default_max_retention_days" {
  type        = number
  description = "The ceiling of retention days that can be configured via a backup plan for the given vault"
  default     = 365
}

variable "default_min_retention_days" {
  type        = number
  description = "The minimum number of retention days that can be configured via a backup plan for the given vault"
  default     = 7
}

variable "default_changeable_for_days" {
  type        = number
  description = "The cooling-off-period during which you can still delete the lock placed on your vault. The AWS default is 3 days. After this period expires, YOUR LOCK CANNOT BE DELETED"
  default     = 7
}
