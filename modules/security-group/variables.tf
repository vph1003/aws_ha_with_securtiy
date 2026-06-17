variable "project_name" {
  description = "Project name used for resource names."
  type        = string
}

variable "environment" {
  description = "Environment name used for resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups are created."
  type        = string
}

variable "my_ip_cidr" {
  description = "CIDR allowed to SSH to the public instance."
  type        = string
}

variable "db_port" {
  description = "Database port allowed from the private web security group."
  type        = number
  default     = 5432
}

variable "vpc_cidr" {
  description = "VPC CIDR block used for internal ALB ingress."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
