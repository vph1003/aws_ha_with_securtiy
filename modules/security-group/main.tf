resource "aws_security_group" "app_alb" {
  name        = "${var.project_name}-${var.environment}-app-alb-sg"
  description = "Allow HTTPS traffic from the CloudFront VPC Origin"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-app-alb-sg"
  })
}

resource "aws_security_group" "tomcat" {
  name        = "${var.project_name}-${var.environment}-tomcat-sg"
  description = "Allow Tomcat traffic from the private app ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Tomcat from app ALB security group"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_alb.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tomcat-sg"
  })
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Allow database traffic from Tomcat instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Database from Tomcat security group"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.tomcat.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-sg"
  })
}
