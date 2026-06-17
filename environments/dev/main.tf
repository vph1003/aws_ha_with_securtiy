data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_caller_identity" "current" {}

locals {
  app_s3_bucket_name = coalesce(
    var.app_s3_bucket_name,
    "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-app"
  )

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

module "vpc" {
  source = "../../modules/vpc"

  project_name                  = var.project_name
  environment                   = var.environment
  vpc_cidr                      = var.vpc_cidr
  public_subnet_cidr            = var.public_subnet_cidr
  public_secondary_subnet_cidr  = var.public_secondary_subnet_cidr
  private_subnet_cidr           = var.private_subnet_cidr
  private_secondary_subnet_cidr = var.private_secondary_subnet_cidr
  db_subnet_cidr                = var.db_subnet_cidr
  db_secondary_subnet_cidr      = var.db_secondary_subnet_cidr
  availability_zone             = var.availability_zone
  secondary_availability_zone   = var.secondary_availability_zone
  enable_nat_gateway            = var.enable_nat_gateway
  tags                          = local.common_tags
}


module "app_s3" {
  source = "../../modules/s3"

  bucket_name   = local.app_s3_bucket_name
  force_destroy = var.app_s3_force_destroy
  tags          = local.common_tags
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "tomcat" {
  name               = "${var.project_name}-${var.environment}-tomcat-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "tomcat_rds_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.rds.master_user_secret_arn]
  }
}

resource "aws_iam_role_policy" "tomcat_rds_secret" {
  name   = "${var.project_name}-${var.environment}-tomcat-rds-secret"
  role   = aws_iam_role.tomcat.id
  policy = data.aws_iam_policy_document.tomcat_rds_secret.json
}

resource "aws_iam_instance_profile" "tomcat" {
  name = "${var.project_name}-${var.environment}-tomcat-profile"
  role = aws_iam_role.tomcat.name

  tags = local.common_tags
}

module "security_group" {
  source = "../../modules/security-group"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  my_ip_cidr   = var.my_ip_cidr
  db_port      = 5432
  vpc_cidr     = var.vpc_cidr
  tags         = local.common_tags
}

module "tomcat_alb" {
  source = "../../modules/alb"

  name                  = "${var.project_name}-${var.environment}-tomcat-alb"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_ids    = [module.security_group.app_alb_sg_id]
  internal              = true
  enable_http_listener  = false
  enable_https_listener = true
  https_listener_port   = 443
  certificate_arn       = aws_acm_certificate_validation.origin_alb.certificate_arn
  target_port           = 8080
  target_type           = "instance"
  health_check_path     = "/"
  tags                  = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  project_name           = var.project_name
  environment            = var.environment
  subnet_ids             = module.vpc.db_subnet_ids
  vpc_security_group_ids = [module.security_group.db_sg_id]
  database_name          = var.db_name
  master_username        = var.db_master_username
  instance_class         = var.db_instance_class
  instance_count         = var.db_instance_count
  tags                   = local.common_tags
}

module "tomcat_asg" {
  source = "../../modules/asg"

  name                      = "${var.project_name}-${var.environment}-tomcat-asg"
  ami_id                    = data.aws_ami.amazon_linux_2023.id
  instance_type             = var.instance_type
  key_name                  = var.key_name
  subnet_ids                = module.vpc.private_subnet_ids
  security_group_ids        = [module.security_group.tomcat_sg_id]
  iam_instance_profile_name = aws_iam_instance_profile.tomcat.name
  target_group_arns         = [module.tomcat_alb.target_group_arn]
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 2
  health_check_type         = "ELB"
  user_data                 = <<-EOT
    #!/bin/bash
    set -eux

    dnf install -y java-17-amazon-corretto-headless tar gzip python3 awscli
    useradd --system --home-dir /opt/tomcat --shell /sbin/nologin tomcat || true

    curl -fL "https://archive.apache.org/dist/tomcat/tomcat-10/v${var.tomcat_version}/bin/apache-tomcat-${var.tomcat_version}.tar.gz" -o /tmp/apache-tomcat.tar.gz
    mkdir -p /opt/tomcat
    tar -xzf /tmp/apache-tomcat.tar.gz -C /opt/tomcat --strip-components=1
    rm -f /tmp/apache-tomcat.tar.gz
    curl -fL "https://repo1.maven.org/maven2/org/postgresql/postgresql/${var.postgres_jdbc_version}/postgresql-${var.postgres_jdbc_version}.jar" -o /opt/tomcat/lib/postgresql.jar

    set +x
    DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "${module.rds.master_user_secret_arn}" --region "${var.aws_region}" --query SecretString --output text | python3 -c 'import json, sys; print(json.load(sys.stdin)["password"])')
    cat > /opt/tomcat/bin/setenv.sh <<ENV
    export DB_HOST="${module.rds.writer_endpoint}"
    export DB_PORT="${module.rds.port}"
    export DB_NAME="${var.db_name}"
    export DB_USER="${var.db_master_username}"
    ENV
    printf 'export DB_PASSWORD=%q\n' "$DB_PASSWORD" >> /opt/tomcat/bin/setenv.sh
    set -x

    rm -rf /opt/tomcat/webapps/ROOT
    mkdir -p /opt/tomcat/webapps/ROOT
    cat > /opt/tomcat/webapps/ROOT/index.html <<'HTML'
    <!doctype html>
    <html lang="ko">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Application</title>
      <style>
        body {
          margin: 0;
          min-height: 100vh;
          display: grid;
          place-items: center;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          background: #0f172a;
          color: #f8fafc;
        }
        main {
          width: min(720px, calc(100% - 40px));
        }
        h1 {
          margin: 0 0 16px;
          font-size: 38px;
        }
        p {
          color: #cbd5e1;
          line-height: 1.7;
        }
        a {
          color: #5eead4;
          font-weight: 700;
        }
      </style>
    </head>
    <body>
      <main>
        <h1>Application service is running</h1>
        <p>이 페이지는 CloudFront VPC Origin과 private ALB를 통해 Tomcat에서 제공됩니다.</p>
        <p><a href="/health.jsp">서비스 상태 확인</a></p>
      </main>
    </body>
    </html>
    HTML
    cat > /opt/tomcat/webapps/ROOT/health.jsp <<'JSP'
    <%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
    <!doctype html>
    <html lang="ko">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Service Health</title>
      <style>
        body {
          margin: 0;
          min-height: 100vh;
          display: grid;
          place-items: center;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          background: #0f172a;
          color: #f8fafc;
        }
        main {
          width: min(720px, calc(100% - 40px));
        }
        .status {
          display: inline-flex;
          margin-bottom: 18px;
          padding: 8px 12px;
          border-radius: 999px;
          background: rgba(45, 212, 191, 0.14);
          color: #5eead4;
          font-weight: 800;
        }
        .status.fail {
          background: rgba(248, 113, 113, 0.14);
          color: #fca5a5;
        }
        h1 {
          margin: 0 0 16px;
          font-size: 38px;
        }
        p {
          color: #cbd5e1;
          line-height: 1.7;
        }
        a {
          color: #5eead4;
          font-weight: 700;
        }
      </style>
    </head>
    <body>
    <%
      String host = System.getenv("DB_HOST");
      String port = System.getenv("DB_PORT");
      String dbName = System.getenv("DB_NAME");
      String user = System.getenv("DB_USER");
      String password = System.getenv("DB_PASSWORD");
      String url = "jdbc:postgresql://" + host + ":" + port + "/" + dbName;

      try {
        Class.forName("org.postgresql.Driver");
        try (
          Connection conn = DriverManager.getConnection(url, user, password);
          Statement stmt = conn.createStatement();
          ResultSet rs = stmt.executeQuery("select 1")
        ) {
          if (rs.next()) {
    %>
    <main>
      <span class="status">HEALTHY</span>
      <h1>Service is available</h1>
      <p>애플리케이션 서버와 데이터 계층이 정상적으로 응답했습니다.</p>
      <p><a href="/">애플리케이션으로 돌아가기</a></p>
    </main>
    <%
          }
        }
      } catch (Exception e) {
        response.setStatus(500);
    %>
    <main>
      <span class="status fail">UNAVAILABLE</span>
      <h1>Service is temporarily unavailable</h1>
      <p>현재 서비스 상태 확인에 실패했습니다. 잠시 후 다시 시도해 주세요.</p>
      <p><a href="/">애플리케이션으로 돌아가기</a></p>
    </main>
    <%
      }
    %>
    </body>
    </html>
    JSP
    chown -R tomcat:tomcat /opt/tomcat
    chmod 600 /opt/tomcat/bin/setenv.sh
    chmod +x /opt/tomcat/bin/*.sh

    cat > /etc/systemd/system/tomcat.service <<'SERVICE'
    [Unit]
    Description=Apache Tomcat
    After=network.target

    [Service]
    Type=forking
    User=tomcat
    Group=tomcat
    Environment=JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
    Environment=CATALINA_HOME=/opt/tomcat
    Environment=CATALINA_BASE=/opt/tomcat
    ExecStart=/opt/tomcat/bin/startup.sh
    ExecStop=/opt/tomcat/bin/shutdown.sh
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable --now tomcat
  EOT
  tags                      = local.common_tags

  depends_on = [
    aws_iam_role_policy.tomcat_rds_secret,
    module.rds
  ]
}
