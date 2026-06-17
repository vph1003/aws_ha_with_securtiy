locals {
  cluster_identifier = coalesce(
    var.cluster_identifier,
    "${var.project_name}-${var.environment}-aurora"
  )
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.cluster_identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${local.cluster_identifier}-subnet-group"
  })
}

resource "aws_rds_cluster" "this" {
  cluster_identifier          = local.cluster_identifier
  database_name               = var.database_name
  master_username             = var.master_username
  manage_master_user_password = true
  engine                      = var.engine
  engine_version              = var.engine_version
  port                        = var.port
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = var.vpc_security_group_ids
  backup_retention_period     = var.backup_retention_period
  storage_encrypted           = true
  skip_final_snapshot         = var.skip_final_snapshot
  deletion_protection         = var.deletion_protection

  tags = merge(var.tags, {
    Name = local.cluster_identifier
  })
}

resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier          = "${local.cluster_identifier}-${count.index + 1}"
  cluster_identifier  = aws_rds_cluster.this.id
  instance_class      = var.instance_class
  engine              = aws_rds_cluster.this.engine
  engine_version      = aws_rds_cluster.this.engine_version
  publicly_accessible = false

  tags = merge(var.tags, {
    Name = "${local.cluster_identifier}-${count.index + 1}"
  })
}
