output "app_alb_sg_id" {
  description = "Private app ALB security group ID."
  value       = aws_security_group.app_alb.id
}

output "tomcat_sg_id" {
  description = "Tomcat security group ID."
  value       = aws_security_group.tomcat.id
}

output "db_sg_id" {
  description = "Database security group ID."
  value       = aws_security_group.db.id
}
