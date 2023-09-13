resource "aws_s3_bucket" "yyq" {
  bucket = "p3l1"
}

resource "aws_s3_bucket_ownership_controls" "yyq" {
  bucket = aws_s3_bucket.yyq.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "yyq" {
  bucket = aws_s3_bucket.yyq.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "yyq" {
  depends_on = [
    aws_s3_bucket_ownership_controls.yyq,
    aws_s3_bucket_public_access_block.yyq,
  ]

  bucket = aws_s3_bucket.yyq.id
  acl    = "public-read"
}



resource "aws_iam_policy" "s3_logs_policy" {
  name        = "S3LogsPolicy"
  description = "Custom policy for S3 logs access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetBucketAcl",
          "s3:PutBucketAcl",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::mylogs.s3.amazonaws.com",
          "arn:aws:s3:::mylogs.s3.amazonaws.com/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "attach_s3_logs_policy" {
  name       = "attach_s3_logs_policy"
  policy_arn = aws_iam_policy.s3_logs_policy.arn
  users      = ["20230911"]
}





resource "aws_cloudfront_origin_access_control" "example" {
  name                              = "example"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "yyq_distribution" {
  origin {
    domain_name              = aws_s3_bucket.yyq.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.example.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "mylogs.s3.amazonaws.com"
    prefix          = "myprefix"
  }

  aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}