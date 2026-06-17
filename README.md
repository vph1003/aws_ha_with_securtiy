# Project1: CloudFront Private Origins

`project1`은 CloudFront를 단일 진입점으로 두고, 정적 콘텐츠는 private S3에서 제공하며 동적 요청은 CloudFront VPC Origin을 통해 private ALB와 Tomcat으로 전달하는 3-tier Terraform 예제입니다.

## Architecture

```text
User
  |
Route53: cdn.example.com
  |
CloudFront + WAF
  |-- /, /styles.css --------------> Private S3
  |                                    - Public Access Block
  |                                    - CloudFront OAC only
  |
  `-- /app/* ----------------------> CloudFront VPC Origin
                                       |
                                     Private ALB
                                       |
                                     Tomcat ASG
                                       |
                                     Aurora PostgreSQL
```

## Request Routing

CloudFront는 path pattern 기준으로 origin을 나눕니다.

```text
/                 -> Private S3
/styles.css       -> Private S3
/app/             -> Private ALB -> Tomcat /
/app/health.jsp   -> Private ALB -> Tomcat /health.jsp
```

- `/`: S3에 업로드된 `site/index.html`을 제공합니다.
- `/styles.css`: S3에 업로드된 CSS를 제공합니다.
- `/app/`: CloudFront VPC Origin을 통해 private ALB로 전달되고, Tomcat의 `/` 페이지를 보여줍니다.
- `/app/health.jsp`: CloudFront VPC Origin을 통해 private ALB로 전달되고, Tomcat의 `/health.jsp` 상태 페이지를 보여줍니다.
- `/health.jsp`: CloudFront의 `/app/*` path pattern에 걸리지 않으므로 S3 origin으로 가며, S3에 해당 object가 없으면 Access Denied 또는 403이 나는 것이 정상입니다.

CloudFront Function이 `/app` prefix를 제거합니다.

```text
Viewer request: /app/            -> Origin request: /
Viewer request: /app/health.jsp -> Origin request: /health.jsp
```

## Security

- S3 bucket은 public access를 차단합니다.
- S3 object는 CloudFront Origin Access Control만 읽을 수 있습니다.
- ALB는 internet-facing이 아니라 internal ALB입니다.
- ALB security group은 CloudFront VPC Origin service-managed security group의 HTTPS 요청만 허용합니다.
- Tomcat은 private subnet의 ASG에서 실행됩니다.
- Tomcat은 Secrets Manager에서 DB password를 읽고 Aurora PostgreSQL에 연결합니다.
- CloudFront에는 AWS Managed Common Rule Set 기반 WAF가 연결됩니다.

## Providers and Regions

기본 AWS provider는 `ap-northeast-2`를 사용합니다.

```hcl
provider "aws" {
  region = var.aws_region
}
```

따라서 VPC, subnet, NAT Gateway, S3, ALB, ASG, EC2, RDS, CloudWatch Logs, IAM role 등 대부분의 리소스는 서울 리전에 생성됩니다.

CloudFront viewer certificate용 ACM 인증서는 반드시 `us-east-1`에 있어야 하므로 alias provider를 추가로 사용합니다.

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
```

이 alias provider는 CloudFront용 ACM certificate, certificate validation, CloudFront WAF에 사용합니다.

## State

현재 `project1`은 local backend를 사용합니다.

```text
terraform/project1/environments/dev/terraform.tfstate
```

`terraform.tfstate`는 로컬 인프라 상태 파일이므로 Git에 올리지 않습니다. S3 backend 예시는 `backend-dev.hcl.example`에 남겨두었지만, 이 프로젝트에서는 기본적으로 활성화하지 않습니다.

## Directory

```text
terraform/project1/
├── README.md
├── environments/
│   └── dev/
│       ├── backend.tf
│       ├── backend-dev.hcl.example
│       ├── cloudfront.tf
│       ├── flow-logs.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── provider.tf
│       ├── static-site.tf
│       ├── terraform.tfvars.example
│       ├── variables.tf
│       └── site/
│           ├── index.html
│           └── styles.css
└── modules/
    ├── alb/
    ├── asg/
    ├── rds/
    ├── s3/
    ├── security-group/
    └── vpc/
```

## Usage

```bash
cd terraform/project1/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -recursive ../../
terraform validate
terraform plan
terraform apply
```

적용 후 출력값으로 접속 URL을 확인합니다.

```bash
terraform output static_site_url
terraform output tomcat_application_url
```

## Updating Tomcat Pages

Tomcat 페이지는 ASG launch template의 `user_data`로 생성됩니다. `main.tf`의 Tomcat HTML/JSP 내용을 바꾼 뒤에는 새 EC2 인스턴스가 떠야 화면에 반영됩니다.

이 프로젝트의 ASG 모듈에는 `instance_refresh`가 포함되어 있어 launch template 변경 시 rolling refresh를 수행할 수 있습니다. 필요하면 수동으로도 refresh를 시작할 수 있습니다.

```bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name project1-dev-tomcat-asg \
  --region ap-northeast-2
```
