output "cluster_id" {
  description = "Aurora cluster ID."
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "Aurora cluster ARN."
  value       = aws_rds_cluster.this.arn
}

output "writer_endpoint" {
  description = "Read/write cluster endpoint."
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Read-only cluster reader endpoint."
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Database port."
  value       = aws_rds_cluster.this.port
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret ARN for the managed master password."
  value       = try(aws_rds_cluster.this.master_user_secret[0].secret_arn, null)
}
