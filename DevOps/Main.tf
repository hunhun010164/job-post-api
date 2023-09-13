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

resource "aws_iam_policy" "custom_s3_policy" {
  name        = "CustomS3Policy"
  description = "Custom IAM policy for S3"

  # 这里定义自定义的 S3 权限策略
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.yyq.arn}/*",
        "${aws_s3_bucket.yyq.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "custom_s3_attachment" {
  name       = "custom_s3_attachment"
  policy_arn = aws_iam_policy.custom_s3_policy.arn
  # 将策略附加到适当的 IAM 用户或角色上，这里可以是您的用户或角色的名称列表
  users      = ["20230911"]
}