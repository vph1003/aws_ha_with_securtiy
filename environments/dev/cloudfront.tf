locals {
  cloudfront_alb_origin_id = "${var.project_name}-${var.environment}-tomcat-alb-vpc-origin"
  cloudfront_s3_origin_id  = "${var.project_name}-${var.environment}-static-s3-origin"
}

data "aws_route53_zone" "root" {
  name         = "${var.root_domain_name}."
  private_zone = false
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name       = var.certificate_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudfront-cert"
  })
}

resource "aws_acm_certificate" "origin_alb" {
  domain_name       = var.certificate_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-origin-alb-cert"
  })
}

resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for option in aws_acm_certificate.cloudfront.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.root.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}

resource "aws_route53_record" "origin_alb_cert_validation" {
  for_each = {
    for option in aws_acm_certificate.origin_alb.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.root.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "origin_alb" {
  certificate_arn         = aws_acm_certificate.origin_alb.arn
  validation_record_fqdns = [for record in aws_route53_record.origin_alb_cert_validation : record.fqdn]
}

resource "aws_route53_record" "origin" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = var.origin_domain_name
  type    = "A"

  alias {
    name                   = module.tomcat_alb.alb_dns_name
    zone_id                = module.tomcat_alb.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_vpc_origin" "tomcat_alb" {
  vpc_origin_endpoint_config {
    name                   = local.cloudfront_alb_origin_id
    arn                    = module.tomcat_alb.alb_arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "https-only"

    origin_ssl_protocols {
      quantity = 1
      items    = ["TLSv1.2"]
    }
  }

  tags = merge(local.common_tags, {
    Name = local.cloudfront_alb_origin_id
  })

  depends_on = [module.tomcat_alb]
}

resource "aws_cloudfront_origin_access_control" "static_s3" {
  name                              = "${var.project_name}-${var.environment}-static-s3-oac"
  description                       = "Allow CloudFront to read the private static content bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "strip_app_prefix" {
  name    = "${var.project_name}-${var.environment}-strip-app-prefix"
  runtime = "cloudfront-js-2.0"
  comment = "Strip the /app prefix before forwarding requests to Tomcat"
  publish = true
  code    = <<-JAVASCRIPT
    function handler(event) {
      var request = event.request;

      if (request.uri === '/app' || request.uri === '/app/') {
        request.uri = '/';
      } else if (request.uri.indexOf('/app/') === 0) {
        request.uri = request.uri.substring(4);
      }

      return request;
    }
  JAVASCRIPT
}

resource "aws_wafv2_web_acl" "cloudfront" {
  provider = aws.us_east_1

  name        = "${var.project_name}-${var.environment}-cloudfront-waf"
  description = "Basic CloudFront WAF for ${var.project_name}-${var.environment}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-managed-rules-common"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront-waf"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudfront-waf"
  })
}

data "aws_security_group" "cloudfront_vpc_origin" {
  depends_on = [aws_cloudfront_vpc_origin.tomcat_alb]

  filter {
    name   = "group-name"
    values = ["CloudFront-VPCOrigins-Service-SG"]
  }

  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
}

resource "aws_vpc_security_group_ingress_rule" "tomcat_alb_from_cloudfront_vpc_origin" {
  security_group_id            = module.security_group.app_alb_sg_id
  referenced_security_group_id = data.aws_security_group.cloudfront_vpc_origin.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS from CloudFront VPC Origin service-managed SG"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-tomcat-alb-from-cloudfront"
  })
}

resource "aws_cloudfront_distribution" "web" {
  enabled             = true
  is_ipv6_enabled     = false
  comment             = "${var.project_name}-${var.environment} private S3 and private ALB distribution"
  aliases             = [var.cloudfront_domain_name]
  default_root_object = "index.html"
  price_class         = "PriceClass_200"
  web_acl_id          = aws_wafv2_web_acl.cloudfront.arn

  origin {
    domain_name              = module.app_s3.bucket_regional_domain_name
    origin_id                = local.cloudfront_s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.static_s3.id
  }

  origin {
    domain_name = var.origin_domain_name
    origin_id   = local.cloudfront_alb_origin_id

    vpc_origin_config {
      vpc_origin_id = aws_cloudfront_vpc_origin.tomcat_alb.id
    }
  }

  default_cache_behavior {
    target_origin_id       = local.cloudfront_s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
  }

  ordered_cache_behavior {
    path_pattern             = "/app/*"
    target_origin_id         = local.cloudfront_alb_origin_id
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.strip_app_prefix.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudfront"
  })

  depends_on = [
    aws_route53_record.origin,
    aws_vpc_security_group_ingress_rule.tomcat_alb_from_cloudfront_vpc_origin
  ]
}

resource "aws_route53_record" "cdn" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = var.cloudfront_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.web.domain_name
    zone_id                = aws_cloudfront_distribution.web.hosted_zone_id
    evaluate_target_health = false
  }
}
