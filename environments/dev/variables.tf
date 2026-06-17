variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name used for resource names and tags."
  type        = string
  default     = "project1"
}

variable "environment" {
  description = "Environment name used for resource names and tags."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_secondary_subnet_cidr" {
  description = "CIDR block for the second public subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet."
  type        = string
  default     = "10.0.100.0/24"
}

variable "private_secondary_subnet_cidr" {
  description = "CIDR block for the second private subnet."
  type        = string
  default     = "10.0.101.0/24"
}

variable "db_subnet_cidr" {
  description = "CIDR block for the primary database subnet."
  type        = string
  default     = "10.0.200.0/24"
}

variable "db_secondary_subnet_cidr" {
  description = "CIDR block for the second database subnet."
  type        = string
  default     = "10.0.201.0/24"
}

variable "availability_zone" {
  description = "Availability zone to create the practice subnets in."
  type        = string
  default     = "ap-northeast-2a"
}

variable "secondary_availability_zone" {
  description = "Second availability zone for ALB and ASG-ready subnets."
  type        = string
  default     = "ap-northeast-2c"
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for outbound internet access from the private subnet."
  type        = bool
  default     = true
}

variable "app_s3_bucket_name" {
  description = "Private S3 bucket name for CloudFront static content. Leave null to generate one from account, project, environment, and region."
  type        = string
  default     = null
}

variable "app_s3_force_destroy" {
  description = "Whether to delete all objects in the static content S3 bucket during terraform destroy."
  type        = bool
  default     = true
}

variable "root_domain_name" {
  description = "Route53 hosted zone root domain name."
  type        = string
  default     = "example.com"
}

variable "cloudfront_domain_name" {
  description = "Custom domain name for the CloudFront distribution."
  type        = string
  default     = "cdn.example.com"
}

variable "origin_domain_name" {
  description = "Custom origin domain name used by CloudFront to reach the internal ALB."
  type        = string
  default     = "origin.example.com"
}

variable "certificate_domain_name" {
  description = "Wildcard domain name used for ACM certificates."
  type        = string
  default     = "*.example.com"
}

variable "db_name" {
  description = "Initial Aurora PostgreSQL database name."
  type        = string
  default     = "appdb"
}

variable "db_master_username" {
  description = "Aurora PostgreSQL master username. Password is managed by AWS Secrets Manager."
  type        = string
  default     = "dbadmin"
}

variable "db_instance_class" {
  description = "Aurora PostgreSQL DB instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "db_instance_count" {
  description = "Number of Aurora PostgreSQL instances."
  type        = number
  default     = 2
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH access."
  type        = string
  default     = null
}

variable "my_ip_cidr" {
  description = "CIDR allowed to SSH to the public instance. Example: 203.0.113.10/32."
  type        = string
  default     = "203.0.113.10/32"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "tomcat_version" {
  description = "Apache Tomcat version installed on the private Tomcat ASG instances."
  type        = string
  default     = "10.1.34"
}

variable "postgres_jdbc_version" {
  description = "PostgreSQL JDBC driver version installed on the private Tomcat ASG instances."
  type        = string
  default     = "42.7.4"
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
