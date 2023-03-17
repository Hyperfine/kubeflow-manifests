# ------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this
# terraform module.
# ------------------------------------------------------------------------------

variable "name" {
  description = "The name used to namespace all resources created by these templates, including the cluster and cluster instances (e.g. drupaldb). Must be unique in this region. Must be a lowercase string."
  type        = string
}

variable "db_name" {
  description = "The name for your database of up to 8 alpha-numeric characters. If you do not provide a name, Amazon RDS will not create a database in the DB cluster you are creating."
  type        = string
  default     = null
}

variable "master_username" {
  description = "The username for the master user. Required unless this is a secondary database in a global Aurora cluster."
  type        = string
  default     = null
}

variable "master_password" {
  description = "The password for the master user. Required unless this is a secondary database in a global Aurora cluster. If var.snapshot_identifier is non-empty, this value is ignored."
  type        = string
  default     = null
}

variable "instance_count" {
  description = "How many instances to launch. RDS will automatically pick a leader and configure the others as replicas."
  type        = number
}

variable "instance_type" {
  description = "The instance type from an Amazon Aurora supported instance class based on a selected engine_mode. Amazon Aurora supports 2 types of instance classes: Memory Optimized (db.r) and Burstable Performance (db.t). Aurora Global Clusters require instance class of either db.r5 (latest) or db.r4 (current). See AWS documentation on Amazon Aurora supported instance class types: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.DBInstanceClass.html#Concepts.DBInstanceClass.Types"
  type        = string
}

variable "vpc_id" {
  description = "The id of the VPC in which this DB should be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet ids where the database instances should be deployed. In the standard Gruntwork VPC setup, these should be the private persistence subnet ids. This is ignored if create_subnet_group=false."
  type        = list(string)
}

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ------------------------------------------------------------------------------

variable "allow_connections_from_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges that can connect to this DB. In the standard Gruntwork VPC setup, these should be the CIDR blocks of the private app subnets, plus the private subnets in the mgmt VPC."
  type        = list(string)
  default     = []
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. Allowed values: 0, 1, 5, 15, 30, 60. Enhanced Monitoring metrics are useful when you want to see how different processes or threads on a DB instance use the CPU."
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs. Be sure this role exists. It will not be created here. You must specify a MonitoringInterval value other than 0 when you specify a MonitoringRoleARN value that is not empty string."
  type        = string
  default     = null
}

variable "cluster_iam_roles" {
  description = "List of IAM role ARNs to attach to the cluster. Be sure these roles exists. They will not be created here. Serverless aurora does not support attaching IAM roles."
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# DEFINE CONSTANTS
# Generally, these values won't need to be changed.
# ------------------------------------------------------------------------------

# Use the default MySQL port
variable "port" {
  description = "The port the DB will listen on (e.g. 3306)"
  type        = number
  default     = 3306
}

variable "backup_retention_period" {
  description = "How many days to keep backup snapshots around before cleaning them up"
  type        = number
  default     = 21
}

# By default, run backups from 2-3am EST, which is 6-7am UTC
variable "preferred_backup_window" {
  description = "The daily time range during which automated backups are created (e.g. 04:00-09:00). Time zone is UTC. Performance may be degraded while a backup runs."
  type        = string
  default     = "06:00-07:00"
}

variable "backtrack_window" {
  description = "Window to allow Aurora Backtrack a special, in-place, destructive rollback for the entire cluster. Must be specified in seconds. 0=disabled, to maximum of 259200"
  type        = number
  default     = null
}

# By default, do cluster maintenance from 3-4am EST on Sunday, which is 7-8am UTC. For info on whether DB changes cause
# degraded performance or downtime, see:
# http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.DBInstance.Modifying.html
variable "preferred_maintenance_window" {
  description = "The weekly day and time range during which cluster maintenance can occur (e.g. wed:04:00-wed:04:30). Time zone is UTC. Performance may be degraded or there may even be a downtime during maintenance windows. For cluster instance maintenance, see \"cluster_instances_maintenance_window_start_timestamp\""
  type        = string
  default     = "sun:07:00-sun:08:00"
}

variable "auto_minor_version_upgrade" {
  description = "Configure the auto minor version upgrade behavior. This is applied to the cluster instances and indicates if the automatic minor version upgrade of the engine is allowed. Default value is true."
  type        = bool
  default     = true
}

variable "cluster_instances_maintenance_window_start_timestamp" {
  description = "The cluster instances maintenance window start in RFC 3339 timestamp (date and time) format. The default starts at \"wed:00:00-wed:02:00\". Can have any date from any year, only the day of the week will be used. Performance may be degraded or there may even be a downtime during maintenance windows."
  type        = string
  default     = "2017-11-22T00:00:00Z"
}

variable "cluster_instances_minutes_between_maintenance_windows" {
  description = "Amount of time, in minutes, between maintenance windows of the cluster instances"
  type        = number
  default     = 180
}

variable "cluster_instances_maintenance_duration_minutes" {
  description = "Amount of time, in minutes, to allow for DB maintenance windows for the cluster instances"
  type        = number
  default     = 120
}

# By default, only apply changes during the scheduled maintenance window, as certain DB changes cause degraded
# performance or downtime. For more info, see:
# http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.DBInstance.Modifying.html
variable "apply_immediately" {
  description = "Specifies whether any cluster modifications are applied immediately, or during the next maintenance window. Note that cluster modifications may cause degraded performance or downtime."
  type        = bool
  default     = false
}

# Note: you cannot enable encryption on an existing DB, so you have to enable it for the very first deployment. If you
# already created the DB unencrypted, you'll have to create a new one with encryption enabled and migrate your data to
# it. For more info on RDS encryption, see: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html
variable "storage_encrypted" {
  description = "Specifies whether the DB cluster uses encryption for data at rest in the underlying storage for the DB, its automated backups, Read Replicas, and snapshots. Uses the default aws/rds key in KMS."
  type        = bool
  default     = false
}

variable "allow_connections_from_security_groups" {
  description = "Specifies a list of Security Groups to allow connections from."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "The ARN of a KMS key that should be used to encrypt data on disk. Only used if var.storage_encrypted is true. If you leave this null, the default RDS KMS key for the account will be used."
  type        = string
  default     = null
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled. Disabled by default."
  type        = bool
  default     = false
}

variable "custom_tags" {
  description = "A map of custom tags to apply to the Aurora RDS Instance and the Security Group created for it. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "copy_tags_to_snapshot" {
  description = "Copy all the Aurora cluster tags to snapshots. Default is false."
  type        = bool
  default     = false
}

variable "snapshot_identifier" {
  description = "If non-empty, the Aurora cluster will be restored from the given Snapshot ID. This is the Snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05."
  type        = string
  default     = null
}

variable "enable_http_endpoint" {
  description = "If true, enables the HTTP endpoint used for Data API. Only valid when engine_mode is set to serverless."
  type        = bool
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "If non-empty, the Aurora cluster will export the specified logs to Cloudwatch. Must be zero or more of: audit, error, general and slowquery"
  type        = list(string)
  default     = []
}

variable "engine" {
  description = "The name of the database engine to be used for this DB cluster. Valid Values: aurora (for MySQL 5.6-compatible Aurora), aurora-mysql (for MySQL 5.7-compatible Aurora), and aurora-postgresql"
  type        = string
  default     = "aurora-mysql"
}

variable "engine_mode" {
  description = "The DB engine mode of the DB cluster: either provisioned, serverless, parallelquery, multimaster or global which only applies for global database clusters created with Aurora MySQL version 5.6.10a. For higher Aurora MySQL versions, the clusters in a global database use provisioned engine mode.. Limitations and requirements apply to some DB engine modes. See AWS documentation: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraSettingUp.html"
  type        = string
  default     = "provisioned"
}

variable "engine_version" {
  description = "The Amazon Aurora DB engine version for the selected engine and engine_mode. Note: Starting with Aurora MySQL 2.03.2, Aurora engine versions have the following syntax <mysql-major-version>.mysql_aurora.<aurora-mysql-version>. e.g. 5.7.mysql_aurora.2.08.1."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true."
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights is enabled or not. On Aurora MySQL, Performance Insights is not supported on db.t2 or db.t3 DB instance classes."
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data."
  type        = string
  default     = null
}

################
## The scaling parameters below ONLY apply to serverless aurora.
## https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless.how-it-works.html#aurora-serverless.how-it-works.auto-scaling
## You can specify the minimum and maximum ACU. The minimum Aurora capacity unit is the lowest ACU to which the DB cluster can scale down. The
## maximum Aurora capacity unit is the highest ACU to which the DB cluster can scale up. Based on your settings, Aurora Serverless automatically
## creates scaling rules for thresholds for CPU utilization, connections, and available memory.
##
## The below max/min's are in the ACU's.  A good read on the impacts is available here:
##    https://www.jeremydaly.com/aurora-serverless-the-good-the-bad-and-the-scalable/
#################

variable "scaling_configuration_auto_pause" {
  description = "Whether to enable automatic pause. A DB cluster can be paused only when it's idle (it has no connections). If a DB cluster is paused for more than seven days, the DB cluster might be backed up with a snapshot. In this case, the DB cluster is restored when there is a request to connect to it."
  type        = bool
  default     = true
}

variable "scaling_configuration_max_capacity" {
  description = "The maximum capacity. The maximum capacity must be greater than or equal to the minimum capacity. Valid capacity values are 2, 4, 8, 16, 32, 64, 128, and 256."
  type        = number
  default     = 256
}

variable "scaling_configuration_min_capacity" {
  description = "The minimum capacity. The minimum capacity must be lesser than or equal to the maximum capacity. Valid capacity values are 2, 4, 8, 16, 32, 64, 128, and 256."
  type        = number
  default     = 2
}

variable "scaling_configuration_seconds_until_auto_pause" {
  description = "The time, in seconds, before an Aurora DB cluster in serverless mode is paused. Valid values are 300 through 86400."
  type        = number
  default     = 300
}

variable "scaling_configuration_timeout_action" {
  description = "The action to take when the timeout is reached. Valid values: ForceApplyCapacityChange, RollbackCapacityChange. Defaults to RollbackCapacityChange."
  type        = string
  default     = "RollbackCapacityChange"
}

################

variable "db_cluster_parameter_group_name" {
  description = "A cluster parameter group to associate with the cluster. Parameters in a DB cluster parameter group apply to every DB instance in a DB cluster."
  type        = string
  default     = null
}

variable "db_instance_parameter_group_name" {
  description = "An instance parameter group to associate with the cluster instances. Parameters in a DB parameter group apply to a single DB instance in an Aurora DB cluster."
  type        = string
  default     = null
}

variable "publicly_accessible" {
  description = "If you wish to make your database accessible from the public Internet, set this flag to true (WARNING: NOT RECOMMENDED FOR PRODUCTION USAGE!!). The default is false, which means the database is only accessible from within the VPC, which is much more secure."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. Be very careful setting this to true; if you do, and you delete this DB instance, you will not have any backups of the data!"
  type        = bool
  default     = false
}

variable "source_region" {
  description = "Source region for global secondary cluster (if creating a global cluster) or the master cluster (if creating a read replica cluster)."
  type        = string
  default     = null
}

variable "replication_source_identifier" {
  description = "ARN of a source DB cluster or DB instance if this DB cluster is to be created as a Read Replica."
  type        = string
  default     = null
}

variable "global_cluster_identifier" {
  description = "Global cluster identifier when creating the global secondary cluster."
  type        = string
  default     = null
}

variable "ca_cert_identifier" {
  description = "The Certificate Authority (CA) certificate bundle to use on the Aurora DB instances."
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These variables may be optionally passed in by the templates using this module to overwite the defaults.
# ----------------------------------------------------------------------------------------------------------------------

variable "create_subnet_group" {
  description = "If false, the DB will bind to aws_db_subnet_group_name and the CIDR will be ignored (allow_connections_from_cidr_blocks)."
  type        = bool
  default     = true
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

# ---------------------------------------------------------------------------------------------------------------------
# MODULE DEPENDENCIES
# Workaround Terraform limitation where there is no module depends_on.
# See https://github.com/hashicorp/terraform/issues/1178 for more details.
# This can be used to make sure the module resources are created after other bootstrapping resources have been created.
# For example, in AWS, when provisioning a wildcard ACM certificate for a public zone, you need to create several
# verification DNS records - but they must be created in the public zone itself. In this use case, you can pass the public
# zones as a dependency into this module:
# dependencies = flatten([values(aws_route53_zone.public_zones).*.name_servers])
# ---------------------------------------------------------------------------------------------------------------------

variable "dependencies" {
  description = "Create a dependency between the resources in this module to the interpolated values in this list (and thus the source resources). In other words, the resources in this module will now depend on the resources backing the values in this list such that those resources need to be created before the resources in this module, and the resources in this module need to be destroyed before the resources in the list."
  type        = list(string)
  default     = []
}
