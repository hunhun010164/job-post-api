resource "aws_s3_bucket" "yyqp3l1" {
  bucket = "my-tf-yyqp3l1-bucket"
}

resource "aws_s3_bucket_ownership_controls" "yyqp3l1" {
  bucket = aws_s3_bucket.yyqp3l1.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "yyqp3l1" {
  bucket = aws_s3_bucket.yyqp3l1.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "yyqp3l1" {
  depends_on = [
    aws_s3_bucket_ownership_controls.yyqp3l1,
    aws_s3_bucket_public_access_block.yyqp3l1,
  ]

  bucket = aws_s3_bucket.yyqp3l1.id
  acl    = "public-read"
}