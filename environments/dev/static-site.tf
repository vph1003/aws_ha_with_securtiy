resource "aws_s3_object" "index" {
  bucket        = module.app_s3.bucket_name
  key           = "index.html"
  source        = "${path.module}/site/index.html"
  etag          = filemd5("${path.module}/site/index.html")
  content_type  = "text/html; charset=utf-8"
  cache_control = "public, max-age=60"
}

resource "aws_s3_object" "styles" {
  bucket        = module.app_s3.bucket_name
  key           = "styles.css"
  source        = "${path.module}/site/styles.css"
  etag          = filemd5("${path.module}/site/styles.css")
  content_type  = "text/css; charset=utf-8"
  cache_control = "public, max-age=300"
}

data "aws_iam_policy_document" "app_s3_cloudfront" {
  statement {
    sid     = "AllowCloudFrontReadOnly"
    actions = ["s3:GetObject"]
    resources = [
      "${module.app_s3.bucket_arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.web.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "app_s3_cloudfront" {
  bucket = module.app_s3.bucket_name
  policy = data.aws_iam_policy_document.app_s3_cloudfront.json
}
