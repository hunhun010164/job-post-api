resource "aws_s3_bucket" "p3l1" {
  bucket = "p3l1-bucket"
}

resource "aws_s3_bucket_ownership_controls" "p3l1" {
  bucket = aws_s3_bucket.p3l1.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "p3l1" {
  depends_on = [aws_s3_bucket_ownership_controls.p3l1]

  bucket = aws_s3_bucket.p3l1.id
  acl    = "private"
}