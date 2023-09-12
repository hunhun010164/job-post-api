resource "aws_s3_bucket" "p3l1test" {
  bucket = "p3l1test"
}

resource "aws_s3_bucket_ownership_controls" "p3l1test" {
  bucket = aws_s3_bucket.p3l1test.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "p3l1test" {
  bucket = aws_s3_bucket.p3l1test.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "p3l1test" {
  depends_on = [
    aws_s3_bucket_ownership_controls.p3l1,
    aws_s3_bucket_ownership_controls.p3l1test,
    aws_s3_bucket_public_access_block.p3l1test,
  ]

  bucket = aws_s3_bucket.p3l1test.id
  acl    = "public-read"
}
