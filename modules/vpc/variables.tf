variable "project_name" {
  description = "Project name used for resource names."
  type        = string
}

variable "environment" {
  description = "Environment name used for resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
}

variable "public_secondary_subnet_cidr" {
  description = "CIDR block for the second public subnet."
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet."
  type        = string
}

variable "private_secondary_subnet_cidr" {
  description = "CIDR block for the second private subnet."
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR block for the primary database subnet."
  type        = string
}

variable "db_secondary_subnet_cidr" {
  description = "CIDR block for the second database subnet."
  type        = string
}

variable "availability_zone" {
  description = "Primary availability zone for the practice subnets."
  type        = string
}

variable "secondary_availability_zone" {
  description = "Second availability zone for ALB and ASG-ready subnets."
  type        = string
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for outbound internet access from the private subnet."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
