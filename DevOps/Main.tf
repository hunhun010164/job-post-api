resource "aws_iam_policy" "s3_full_access" {
  name        = "S3FullAccess"
  description = "Full access to S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3_full_access_attachment" {
  name       = "s3_full_access_attachment"
  policy_arn = aws_iam_policy.s3_full_access.arn
  users      = ["20230911"]
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


