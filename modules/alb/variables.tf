variable "name" {
  description = "ALB name."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB target group is created."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ALB."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs attached to the ALB."
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal."
  type        = bool
  default     = false
}

variable "listener_port" {
  description = "ALB listener port."
  type        = number
  default     = 80
}

variable "enable_http_listener" {
  description = "Whether to create an HTTP listener."
  type        = bool
  default     = true
}

variable "enable_https_listener" {
  description = "Whether to create an HTTPS listener."
  type        = bool
  default     = false
}

variable "https_listener_port" {
  description = "ALB HTTPS listener port."
  type        = number
  default     = 443
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "target_port" {
  description = "Target group backend port."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Target group health check path."
  type        = string
  default     = "/"
}

variable "target_type" {
  description = "Target group target type. Use instance for EC2/ASG targets, ip for IP targets, lambda for Lambda targets, or alb for ALB targets."
  type        = string
  default     = "instance"

  validation {
    condition     = contains(["instance", "ip", "lambda", "alb"], var.target_type)
    error_message = "target_type must be one of: instance, ip, lambda, alb."
  }
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
