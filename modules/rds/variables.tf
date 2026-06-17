variable "project_name" {
  description = "Project name used for resource names."
  type        = string
}

variable "environment" {
  description = "Environment name used for resource names."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs used by the DB subnet group."
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security group IDs attached to the Aurora cluster."
  type        = list(string)
}

variable "cluster_identifier" {
  description = "Aurora cluster identifier. Leave null to generate one."
  type        = string
  default     = null
}

variable "database_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username. Password is managed by AWS Secrets Manager."
  type        = string
  default     = "dbadmin"
}

variable "engine" {
  description = "Aurora engine."
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Aurora engine version. Leave null to use the AWS default."
  type        = string
  default     = null
}

variable "instance_class" {
  description = "Aurora DB instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "instance_count" {
  description = "Number of Aurora instances. Use at least 2 for writer and reader availability."
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 2
    error_message = "instance_count must be at least 2 for writer and reader endpoints."
  }
}

variable "port" {
  description = "Database port."
  type        = number
  default     = 5432
}

variable "backup_retention_period" {
  description = "Number of days to retain backups."
  type        = number
  default     = 1
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot on destroy."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
