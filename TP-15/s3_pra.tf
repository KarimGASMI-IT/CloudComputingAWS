resource "aws_s3_bucket" "pra" {
  bucket = var.pra_bucket_name
}

resource "aws_s3_bucket_versioning" "pra" {
  bucket = aws_s3_bucket.pra.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pra" {
  bucket = aws_s3_bucket.pra.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pra" {
  bucket = aws_s3_bucket.pra.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "evidence_v1" {
  bucket       = aws_s3_bucket.pra.id
  key          = "restore-demo/app.txt"
  content      = "version-1"
  content_type = "text/plain"
}