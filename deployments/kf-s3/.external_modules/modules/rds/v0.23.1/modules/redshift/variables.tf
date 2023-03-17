# ----------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be passed in by the templates using this module.
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name used to namespace all resources created by these templates, including the DB instance (e.g. drupaldb). Must be unique for this region. May contain only lowercase alphanumeric characters, hyphens."
  type        = string
}

variable "db_name" {
  description = "The name for your database of up to 8 alpha-numeric characters. If you do not provide a name, Amazon RDS will not create a database in the DB cluster you are creating."
  type        = string
  default     = "dev"
}

variable "master_username" {
  description = "The username for the master user. Required unless var.replicate_source_db is set."
  type        = string
  default     = null
}

variable "master_password" {
  description = "The password for the master user. If var.snapshot_identifier is non-empty, this value is ignored. Required unless var.replicate_source_db is set."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "The id of the VPC in which this DB should be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet ids where the database should be deployed. In the standard Gruntwork VPC setup, these should be the private persistence subnet ids."
  type        = list(string)
}

variable "instance_type" {
  description = "The instance type to use for the db (e.g. dc2.large)"
  type        = string
}

variable "number_of_nodes" {
  description = "The number of nodes in the cluster"
  type        = number
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These variables may be optionally passed in by the templates using this module to overwite the defaults.
# ----------------------------------------------------------------------------------------------------------------------

variable "port" {
  description = "The port the DB will listen on (e.g. 3306)"
  type        = number
  default     = 5439
}

variable "create_subnet_group" {
  description = "If false, the DB will bind to aws_db_subnet_group_name and the CIDR will be ignored (allow_connections_from_cidr_blocks)"
  type        = bool
  default     = true
}

variable "cluster_subnet_group_name" {
  description = "The name of the cluster_subnet_group that is created, or an existing one to use if cluster_subnet_group is false. Defaults to var.name if not specified."
  type        = string
  default     = null
}

variable "cluster_subnet_group_description" {
  description = "The description of the cluster_subnet_group that is created. Defaults to 'Subnet group for the var.name DB' if not specified."
  type        = string
  default     = null
}

variable "aws_db_security_group_name" {
  description = "The name of the aws_db_security_group that is created. Defaults to var.name if not specified."
  type        = string
  default     = null
}

variable "aws_db_security_group_description" {
  description = "The description of the aws_db_security_group that is created. Defaults to 'Security group for the var.name DB' if not specified."
  type        = string
  default     = null
}

variable "final_snapshot_name" {
  description = "The name of the final_snapshot_identifier. Defaults to var.name-final-snapshot if not specified."
  type        = string
  default     = null
}

variable "parameter_group_name" {
  description = "Name of a Redshift parameter group to associate."
  type        = string
  default     = null
}

# In nearly all cases, databases should NOT be publicly accessible, however if you're migrating from a PAAS provider like Heroku to AWS, this needs to remain open to the internet.
variable "publicly_accessible" {
  description = "WARNING: - In nearly all cases a database should NOT be publicly accessible. Only set this to true if you want the database open to the internet."
  type        = bool
  default     = false
}

# Note: you cannot enable encryption on an existing DB, so you have to enable it for the very first deployment. If you
# already created the DB unencrypted, you'll have to create a new one with encryption enabled and migrate your data to
# it.
variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "How many days to keep backup snapshots around before cleaning them up. Must be 1 or greater to support read replicas."
  type        = number
  default     = 21
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. Be very careful setting this to true; if you do, and you delete this DB instance, you will not have any backups of the data!"
  type        = bool
  default     = false
}

# By default, do maintenance from 3-4am EST on Sunday, which is 7-8am UTC. For info on whether changes cause degraded
# performance or downtime, see:
# https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html#rs-cluster-maintenance
variable "maintenance_window" {
  description = "The weekly day and time range during which system maintenance can occur (e.g. wed:04:00-wed:04:30). Time zone is UTC. Performance may be degraded or there may even be a downtime during maintenance windows."
  type        = string
  default     = "sun:07:00-sun:08:00"
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. If set to true, you should set var.engine_version to MAJOR.MINOR and omit the .PATCH at the end (e.g., use 5.7 and not 5.7.11); otherwise, you'll get Terraform state drift. See https://www.terraform.io/docs/providers/aws/r/db_instance.html#engine_version for more details."
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Indicates whether major version upgrades (e.g. 9.4.x to 9.5.x) will ever be permitted. Note that these updates must always be manually performed and will never automatically applied."
  type        = bool
  default     = true
}

variable "allow_connections_from_security_groups" {
  description = "A list of Security Groups that can connect to this DB."
  type        = list(string)
  default     = []
}

variable "allow_connections_from_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges that can connect to this DB. Should typically be the CIDR blocks of the private app subnet in this VPC plus the private subnet in the mgmt VPC. This is ignored if create_subnet_group=false."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "The ARN of a KMS key that should be used to encrypt data on disk. Only used if var.storage_encrypted is true. If you leave this blank, the default RDS KMS key for the account will be used."
  type        = string
  default     = null
}

variable "custom_tags" {
  description = "A map of custom tags to apply to the RDS Instance and the Security Group created for it. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "snapshot_identifier" {
  description = "If non-null, the Redshift cluster will be restored from the given Snapshot ID. This is the Snapshot ID you'd find in the Redshift console, e.g: rs:production-2015-06-26-06-05."
  type        = string
  default     = null
}

variable "snapshot_cluster_identifier" {
  description = "If non-null, the name of the cluster the source snapshot was created from."
  type        = string
  default     = null
}

variable "snapshot_owner_account" {
  description = "Required if you are restoring a snapshot you do not own, optional if you own the snapshot. The AWS customer account used to create or copy the snapshot."
  type        = string
  default     = null
}

variable "iam_roles" {
  description = "A list of IAM Role ARNs to associate with the cluster. A Maximum of 10 can be associated to the cluster at any time."
  type        = list(string)
  default     = null
}

variable "enhanced_vpc_routing" {
  description = "If true , enhanced VPC routing is enabled. Forces COPY and UNLOAD traffic between the cluster and data repositories to go through your VPC."
  type        = bool
  default     = false
}

variable "logging" {
  description = "Configures logging information such as queries and connection attempts for the specified Amazon Redshift cluster. If enable is set to true. The bucket_name and s3_key_prefix must be set. The bucket must be in the same region as the cluster and the cluster must have read bucket and put object permission."
  type = object({
    enable        = bool
    bucket_name   = string
    s3_key_prefix = string
  })
  default = {
    enable        = false
    bucket_name   = null
    s3_key_prefix = null
  }
}
