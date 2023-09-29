provider "aws" {
  region = "us-east-1" # You can change this to your preferred region.
}

# S3 Bucket
resource "aws_s3_bucket" "react_app" {
  bucket = "post-job-by-terraform-by-ocean-1"
}
resource "aws_s3_bucket_website_configuration" "react_app_website" {
  bucket = aws_s3_bucket.react_app.id

  index_document {
    suffix = "landing.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "null_resource" "build" {
  provisioner "local-exec" {
    command = "yarn install && yarn run build"
  }

  depends_on = [aws_s3_bucket.react_app]
}

resource "null_resource" "deploy" {
  provisioner "local-exec" {
    command = "aws s3 sync out/ s3://${aws_s3_bucket.react_app.bucket}"
  }

  depends_on = [null_resource.build]
}

# Fetch the existing ACM Certificate
data "aws_acm_certificate" "existing_cert" {
  domain   = "*.siemens.global"
  statuses = ["ISSUED"]
}

# Fetch details of existing hosted zone
data "aws_route53_zone" "existing" {
  name = "siemens.global."
}

# Add cloudfront origin access identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for weather app"
}

# CloudFront
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.react_app.bucket_regional_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.oai.id}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "landing.html"

  aliases             = ["p3l1.siemens.global"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn            = data.aws_acm_certificate.existing_cert.arn
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_100"
}

# Route53 Record for CloudFront
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.existing.zone_id
  name    = "p3l1.siemens.global"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Simple S3 bucket policy for CloudFront to access the bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.react_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.oai.id}"
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.react_app.arn}/*"
      }
    ]
  })
}

# Output the CloudFront domain name to access the app
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}