provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# S3 Bucket 1: Default Configuration
resource "aws_s3_bucket" "default_bucket" {
  bucket = "test-bucket-default-${local.account_id}"
}

# S3 Bucket 2: Server-Side Encryption with KMS
resource "aws_s3_bucket" "encrypted_bucket" {
  bucket = "test-bucket-encrypted-${local.account_id}"
}

resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.encrypted_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# S3 Bucket 3: Public Access
resource "aws_s3_bucket" "public_access_bucket" {
  bucket = "test-bucket-public_access-${local.account_id}"
}

resource "aws_s3_bucket_policy" "public_bucket_policy" {
  bucket = aws_s3_bucket.public_access_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.public.arn}/*"
      }
    ]
  })
}

# S3 Bucket 4: Lifecycle Rule
resource "aws_s3_bucket" "lifecycle_bucket" {
  bucket = "test-bucket-lifecycle-${local.account_id}"
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_bucket" {
  bucket = aws_s3_bucket.lifecycle_bucket.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}
