output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "Public subnet ID."
  value       = aws_subnet.public.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = [aws_subnet.public.id, aws_subnet.public_secondary.id]
}

output "private_subnet_id" {
  description = "Private subnet ID."
  value       = aws_subnet.private.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = [aws_subnet.private.id, aws_subnet.private_secondary.id]
}

output "db_subnet_id" {
  description = "Primary database subnet ID."
  value       = aws_subnet.db.id
}

output "db_subnet_ids" {
  description = "Database subnet IDs."
  value       = [aws_subnet.db.id, aws_subnet.db_secondary.id]
}

output "public_route_table_id" {
  description = "Public route table ID."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private route table ID."
  value       = aws_route_table.private.id
}

output "db_route_table_id" {
  description = "Database route table ID."
  value       = aws_route_table.db.id
}

output "public_network_acl_id" {
  description = "Public subnet network ACL ID."
  value       = aws_network_acl.public.id
}

output "private_network_acl_id" {
  description = "Private subnet network ACL ID."
  value       = aws_network_acl.private.id
}

output "db_network_acl_id" {
  description = "Database subnet network ACL ID."
  value       = aws_network_acl.db.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID, if enabled."
  value       = var.enable_nat_gateway ? aws_nat_gateway.this[0].id : null
}

output "nat_gateway_route_table_id" {
  description = "Regional NAT Gateway managed route table ID, if enabled."
  value       = var.enable_nat_gateway ? aws_nat_gateway.this[0].route_table_id : null
}

output "nat_gateway_availability_mode" {
  description = "NAT Gateway availability mode, if enabled."
  value       = var.enable_nat_gateway ? aws_nat_gateway.this[0].availability_mode : null
}

output "nat_eip_public_ip" {
  description = "NAT Gateway Elastic IP public address. Regional NAT Gateway auto mode does not use this output."
  value       = null
}

output "s3_vpc_endpoint_id" {
  description = "S3 Gateway VPC Endpoint ID."
  value       = aws_vpc_endpoint.s3.id
}
