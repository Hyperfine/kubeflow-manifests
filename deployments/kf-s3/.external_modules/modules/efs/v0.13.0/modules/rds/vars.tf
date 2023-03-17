# ----------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be passed in by the templates using this module.
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name used to namespace all resources created by these templates, including the DB instance (e.g. drupaldb). Must be unique for this region. May contain only lowercase alphanumeric characters, hyphens, underscores, periods, and spaces."
  type        = string
}

variable "db_name" {
  description = "The name for your database of up to 8 alpha-numeric characters. If you do not provide a name, Amazon RDS will not create a database in the DB cluster you are creating."
  type        = string
  default     = null
}

variable "master_username" {
  description = "The username for the master user. Required unless var.replicate_source_db is set."
  type        = string
  default     = null
}

variable "master_password" {
  description = "The password for the master user. If var.snapshot_identifier is non-empty, this value is ignored. Required unless var.replicate_source_db is set."
  type        = string
  default      = null
}

variable "vpc_id" {
  description = "The id of the VPC in which this DB should be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet ids where the database should be deployed. In the standard Gruntwork VPC setup, these should be the private persistence subnet ids."
  type        = list(string)
}

variable "engine" {
  description = "The DB engine to use (e.g. mysql). Required unless var.replicate_source_db is set."
  type        = string
}

variable "engine_version" {
  description = "The version of var.engine to use (e.g. 5.7.11 for mysql). If var.auto_minor_version_upgrade is set to true, set the version number to MAJOR.MINOR and omit the PATCH (e.g., set it to 5.7 and not 5.7.11) to avoid state drift. See https://www.terraform.io/docs/providers/aws/r/db_instance.html#engine_version for more details."
  type        = string
}

variable "port" {
  description = "The port the DB will listen on (e.g. 3306)"
  type        = number
}

variable "allocated_storage" {
  description = "The amount of storage space the DB should use, in GB. If max_allocated_storage is configured, this argument represents the initial storage allocation and differences from the configuration will be ignored automatically when Storage Autoscaling occurs. Required unless var.replicate_source_db is set."
  type        = number
  default     = null
}

variable "instance_type" {
  description = "The instance type to use for the db (e.g. db.t2.micro)"
  type        = string
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These variables may be optionally passed in by the templates using this module to overwite the defaults.
# ----------------------------------------------------------------------------------------------------------------------

variable "create_subnet_group" {
  description = "If false, the DB will bind to aws_db_subnet_group_name and the CIDR will be ignored (allow_connections_from_cidr_blocks)"
  type        = bool
  default     = true
}

variable "monitoring_role_name" {
  description = "The name of the enhanced_monitoring_role that is created. Defaults to var.name-monitoring-role if not specified."
  type        = string
  default     = null
}

variable "aws_db_subnet_group_name" {
  description = "The name of the aws_db_subnet_group that is created, or an existing one to use if create_subnet_group is false. Defaults to var.name if not specified."
  type        = string
  default     = null
}

variable "aws_db_subnet_group_description" {
  description = "The description of the aws_db_subnet_group that is created. Defaults to 'Subnet group for the var.name DB' if not specified."
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

variable "num_read_replicas" {
  description = "The number of read replicas to create. RDS will asynchronously replicate all data from the master to these replicas, which you can use to horizontally scale reads traffic."
  type        = number
  default     = 0
}

variable "option_group_name" {
  description = "Name of a DB option group to associate."
  type        = string
  default     = null
}

variable "parameter_group_name" {
  description = "Name of a DB parameter group to associate."
  type        = string
  default     = null
}

variable "parameter_group_name_for_read_replicas" {
  description = "Name of a DB parameter group to associate with read replica instances. Defaults to var.parameter_group_name if not set."
  type        = string
  default     = null
}

variable "storage_type" {
  description = "The type of storage to use. Must be one of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD)."
  type        = string
  default     = "gp2"
}

# In nearly all cases, databases should NOT be publicly accessible, however if you're migrating from a PAAS provider like Heroku to AWS, this needs to remain open to the internet.
variable "publicly_accessible" {
  description = "WARNING: - In nearly all cases a database should NOT be publicly accessible. Only set this to true if you want the database open to the internet."
  type        = bool
  default     = false
}

# Note: you cannot enable encryption on an existing DB, so you have to enable it for the very first deployment. If you
# already created the DB unencrypted, you'll have to create a new one with encryption enabled and migrate your data to
# it. For more info on RDS encryption, see: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html
variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted."
  type        = bool
  default     = false
}

variable "iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1'. Set to 0 to disable."
  type        = number
  default     = 0
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

# By default, run backups from 2-3am EST, which is 6-7am UTC
variable "backup_window" {
  description = "The daily time range during which automated backups are created (e.g. 04:00-09:00). Time zone is UTC. Performance may be degraded while a backup runs."
  type        = string
  default     = "06:00-07:00"
}

# By default, do maintenance from 3-4am EST on Sunday, which is 7-8am UTC. For info on whether DB changes cause
# degraded performance or downtime, see:
# http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.DBInstance.Modifying.html
variable "maintenance_window" {
  description = "The weekly day and time range during which system maintenance can occur (e.g. wed:04:00-wed:04:30). Time zone is UTC. Performance may be degraded or there may even be a downtime during maintenance windows."
  type        = string
  default     = "sun:07:00-sun:08:00"
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. Valid Values: 0, 1, 5, 10, 15, 30, 60."
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs. If monitoring_interval is greater than 0, but monitoring_role_arn is let as an empty string, a default IAM role that allows enhanced monitoring will be created."
  type        = string
  default     = null
}

variable "monitoring_role_arn_path" {
  description = "Optionally add a path to the IAM monitoring role. If left blank, it will default to just /."
  type        = string
  default     = "/"
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL) and upgrade (PostgreSQL)."
  type        = list(string)
  default     = []
}

# By default, only apply changes during the scheduled maintenance window, as certain DB changes cause degraded
# performance or downtime. For more info, see:
# http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.DBInstance.Modifying.html
variable "apply_immediately" {
  description = "Specifies whether any cluster modifications are applied immediately, or during the next maintenance window. Note that cluster modifications may cause degraded performance or downtime."
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Specifies if a standby instance should be deployed in another availability zone. If the primary fails, this instance will automatically take over."
  type        = bool
  default     = true
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

variable "allow_connections_from_security_groups_to_read_replicas" {
  description = "A list of Security Groups that can connect to read replica instances. If not set read replica instances will use the same security group as master instance."
  type        = list(string)
  default     = []
}

variable "allow_connections_from_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges that can connect to this DB. Should typically be the CIDR blocks of the private app subnet in this VPC plus the private subnet in the mgmt VPC. This is ignored if create_subnet_group=false."
  type        = list(string)
  default     = []
}

variable "allow_connections_from_cidr_blocks_to_read_replicas" {
  description = "A list of CIDR-formatted IP address ranges that can connect to read replica instances. If not set read replica instances will use the same security group as master instance."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "The ARN of a KMS key that should be used to encrypt data on disk. Only used if var.storage_encrypted is true. If you leave this blank, the default RDS KMS key for the account will be used."
  type        = string
  default     = null
}

variable "license_model" {
  description = "The license model to use for this DB. Check the docs for your RDS DB for available license models. Valid values: general-public-license, postgresql-license, license-included, bring-your-own-license."
  type        = string
  default     = null
}

variable "default_license_models" {
  description = "A map of the default license to use for each supported RDS engine."
  type        = map(string)

  default = {
    mariadb       = "general-public-license"
    mysql         = "general-public-license"
    oracle-ee     = "bring-your-own-license"
    oracle-se2    = "bring-your-own-license"
    oracle-se1    = "bring-your-own-license"
    oracle-se     = "bring-your-own-license"
    postgres      = "postgresql-license"
    sqlserver-ee  = "license-included"
    sqlserver-se  = "license-included"
    sqlserver-ex  = "license-included"
    sqlserver-web = "license-included"
  }
}

variable "custom_tags" {
  description = "A map of custom tags to apply to the RDS Instance and the Security Group created for it. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "copy_tags_to_snapshot" {
  description = "Copy all the RDS instance tags to snapshots. Default is false."
  type        = bool
  default     = false
}

variable "snapshot_identifier" {
  description = "If non-null, the RDS Instance will be restored from the given Snapshot ID. This is the Snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05."
  type        = string
  default     = null
}

variable "max_allocated_storage" {
  description = "When configured, the upper limit to which Amazon RDS can automatically scale the storage of the DB instance. Configuring this will automatically ignore differences to allocated_storage. Must be greater than or equal to allocated_storage or 0 to disable Storage Autoscaling."
  type        = number
  default     = 0
}

variable "ca_cert_identifier" {
  description = "The Certificate Authority (CA) certificates bundle to use on the RDS instance."
  type        = string
  default     = null
}

variable "allowed_replica_zones" {
  description = "The availability zones within which it should be possible to spin up replicas"
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  description = "The database can't be deleted when this value is set to true. The default is false."
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled. Performance Insights can be enabled for specific versions of database engines. See https://aws.amazon.com/rds/performance-insights/ for more details."
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data. When specifying performance_insights_kms_key_id, performance_insights_enabled needs to be set to true. Once KMS key is set, it can never be changed. When set to `null` default aws/rds KMS for given region is used."
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years). When specifying performance_insights_retention_period, performance_insights_enabled needs to be set to true. Defaults to `7`."
  type        = number
  default     = null
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether IAM database authentication is enabled. This option is only available for MySQL and PostgreSQL engines."
  type        = bool
  default     = null
}

variable "replicate_source_db" {
  description = "Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate (if replicating within a single region) or ARN of the Amazon RDS Database to replicate (if replicating cross-region). Note that if you are creating a cross-region replica of an encrypted database you will also need to specify a kms_key_arn."
  type        = string
  default     = null
}