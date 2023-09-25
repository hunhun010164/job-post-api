provider "aws" {
  region = "us-east-1"
}


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



resource "aws_route53_zone" "example_zone" {
  name = "p3.siemens.global"
}

resource "aws_route53_record" "example_record" {
  zone_id = aws_route53_zone.example_zone.zone_id
  name    = "@"
  type    = "A"

  ttl = "300"

  records = ["1.1.1.1"]
}



resource "aws_cloudfront_origin_access_control" "example" {
  name                              = "example"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  s3_origin_id = "p3l1"
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
    bucket          = "p3l1.s3.amazonaws.com"
    prefix          = "myprefix"
  }

  aliases = ["p3.siemens.global"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS","POST"]
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
      restriction_type = "none"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.example.arn
  }
}

resource "aws_acm_certificate" "example" {
  domain_name       = "p3.siemens.global"
  validation_method = "DNS"
}

data "aws_acm_certificate" "example" {
  domain   = "p3.siemens.global"
  statuses = ["ISSUED"]
}

