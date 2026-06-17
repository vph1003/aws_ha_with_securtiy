variable "name" {
  description = "Auto Scaling Group name prefix."
  type        = string
}

variable "ami_id" {
  description = "AMI ID for instances launched by the ASG."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnets used by the ASG."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to ASG instances."
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name attached to ASG instances."
  type        = string
  default     = null
}

variable "target_group_arns" {
  description = "Target group ARNs attached to the ASG."
  type        = list(string)
  default     = []
}

variable "desired_capacity" {
  description = "Desired number of instances."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of instances."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances."
  type        = number
  default     = 2
}

variable "health_check_type" {
  description = "Health check type for the ASG. Use EC2 or ELB."
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Time, in seconds, after instance launch before checking health."
  type        = number
  default     = 300
}

variable "user_data" {
  description = "User data script."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
