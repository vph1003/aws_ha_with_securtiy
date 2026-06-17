output "vpc_id" {
  description = "Created VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID."
  value       = module.vpc.public_subnet_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_id" {
  description = "Private subnet ID."
  value       = module.vpc.private_subnet_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "private_subnet_flow_log_group_name" {
  description = "CloudWatch Logs group name for private subnet VPC Flow Logs."
  value       = aws_cloudwatch_log_group.private_subnet_flow_logs.name
}

output "db_subnet_id" {
  description = "Primary database subnet ID."
  value       = module.vpc.db_subnet_id
}

output "db_subnet_ids" {
  description = "Database subnet IDs."
  value       = module.vpc.db_subnet_ids
}

output "public_network_acl_id" {
  description = "Public subnet network ACL ID."
  value       = module.vpc.public_network_acl_id
}

output "private_network_acl_id" {
  description = "Private subnet network ACL ID."
  value       = module.vpc.private_network_acl_id
}

output "db_network_acl_id" {
  description = "Database subnet network ACL ID."
  value       = module.vpc.db_network_acl_id
}

output "db_route_table_id" {
  description = "Database route table ID."
  value       = module.vpc.db_route_table_id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID, if enabled."
  value       = module.vpc.nat_gateway_id
}

output "nat_gateway_route_table_id" {
  description = "Regional NAT Gateway managed route table ID, if enabled."
  value       = module.vpc.nat_gateway_route_table_id
}

output "nat_gateway_availability_mode" {
  description = "NAT Gateway availability mode, if enabled."
  value       = module.vpc.nat_gateway_availability_mode
}

output "nat_eip_public_ip" {
  description = "NAT Gateway Elastic IP public address. Regional NAT Gateway auto mode does not use this output."
  value       = module.vpc.nat_eip_public_ip
}

output "s3_vpc_endpoint_id" {
  description = "S3 Gateway VPC Endpoint ID."
  value       = module.vpc.s3_vpc_endpoint_id
}

output "app_s3_bucket_name" {
  description = "Private S3 bucket name used by the CloudFront static origin."
  value       = module.app_s3.bucket_name
}

output "tomcat_instance_profile_name" {
  description = "IAM instance profile used by the Tomcat Auto Scaling Group."
  value       = aws_iam_instance_profile.tomcat.name
}

output "static_site_url" {
  description = "HTTPS URL for the CloudFront-hosted static site."
  value       = "https://${var.cloudfront_domain_name}/"
}

output "tomcat_application_url" {
  description = "HTTPS URL routed by CloudFront to the private Tomcat ALB."
  value       = "https://${var.cloudfront_domain_name}/app/"
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.web.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.web.id
}

output "cloudfront_custom_domain_name" {
  description = "Route53 custom domain name for CloudFront."
  value       = var.cloudfront_domain_name
}

output "cloudfront_origin_domain_name" {
  description = "Route53 origin domain name for the internal ALB."
  value       = var.origin_domain_name
}

output "cloudfront_vpc_origin_id" {
  description = "CloudFront VPC origin ID."
  value       = aws_cloudfront_vpc_origin.tomcat_alb.id
}

output "cloudfront_certificate_arn" {
  description = "ACM certificate ARN used by CloudFront."
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "origin_alb_certificate_arn" {
  description = "ACM certificate ARN used by the internal ALB HTTPS listener."
  value       = aws_acm_certificate_validation.origin_alb.certificate_arn
}

output "tomcat_alb_dns_name" {
  description = "Private Tomcat ALB DNS name."
  value       = module.tomcat_alb.alb_dns_name
}

output "tomcat_alb_target_group_arn" {
  description = "Private Tomcat ALB target group ARN attached to the Tomcat ASG."
  value       = module.tomcat_alb.target_group_arn
}

output "tomcat_asg_name" {
  description = "Tomcat Auto Scaling Group name."
  value       = module.tomcat_asg.autoscaling_group_name
}

output "rds_writer_endpoint" {
  description = "Aurora PostgreSQL read/write endpoint."
  value       = module.rds.writer_endpoint
}

output "rds_reader_endpoint" {
  description = "Aurora PostgreSQL read-only endpoint."
  value       = module.rds.reader_endpoint
}

output "rds_port" {
  description = "Aurora PostgreSQL database port."
  value       = module.rds.port
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager secret ARN for the Aurora PostgreSQL master password."
  value       = module.rds.master_user_secret_arn
}
