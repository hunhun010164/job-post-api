resource "aws_s3_bucket" "p3l1" {
  bucket = "p3l1"
}

resource "aws_s3_bucket_ownership_controls" "p3l1" {
  bucket = aws_s3_bucket.p3l1.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "p3l1" {
  bucket = aws_s3_bucket.p3l1.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "p3l1" {
  depends_on = [
    aws_s3_bucket_ownership_controls.p3l1,
    aws_s3_bucket_public_access_block.p3l1,
  ]

  bucket = aws_s3_bucket.p3l1.id
  acl    = "public-read"
}