resource "aws_cloudwatch_log_group" "private_subnet_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}-${var.environment}/private-subnets"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-flow-logs"
  })
}

data "aws_iam_policy_document" "vpc_flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name               = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "vpc_flow_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.private_subnet_flow_logs.arn}:*"]
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name   = "${var.project_name}-${var.environment}-vpc-flow-logs"
  role   = aws_iam_role.vpc_flow_logs.id
  policy = data.aws_iam_policy_document.vpc_flow_logs.json
}

resource "aws_flow_log" "private_subnets" {
  for_each = {
    primary   = module.vpc.private_subnet_ids[0]
    secondary = module.vpc.private_subnet_ids[1]
  }

  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.private_subnet_flow_logs.arn
  traffic_type    = "ALL"
  subnet_id       = each.value

  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-flow-log"
  })

  depends_on = [aws_iam_role_policy.vpc_flow_logs]
}
