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

- `/`: S3에 업로드된 `site/index.html`을 제공합니다.
- `/styles.css`: S3에 업로드된 CSS를 제공합니다.
- `/app/*`: private ALB의 Tomcat으로 전달합니다.
- `/app/health.jsp`: Tomcat에서 내부 상태를 확인하되 DB endpoint, DB명, 사용자명, stacktrace는 화면에 노출하지 않습니다.

CloudFront Function이 `/app` prefix를 제거합니다.

```text
/app/            -> /
/app/health.jsp -> /health.jsp
```

## Security

- S3 bucket은 public access를 차단합니다.
- S3 object는 CloudFront Origin Access Control만 읽을 수 있습니다.
- ALB는 internet-facing이 아니라 internal ALB입니다.
- ALB security group은 CloudFront VPC Origin service-managed security group의 HTTPS 요청만 허용합니다.
- Tomcat은 private subnet의 ASG에서 실행됩니다.
- Tomcat은 Secrets Manager에서 DB password를 읽고 Aurora PostgreSQL에 연결합니다.
- CloudFront에는 AWS Managed Common Rule Set 기반 WAF가 연결됩니다.

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
