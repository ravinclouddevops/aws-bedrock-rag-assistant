locals {
  bucket_name = "${var.project_name}-corpus-${var.environment}-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ---------------------------------------------------------------------------
# S3 — Document corpus for Bedrock Knowledge Base ingestion
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "kb_corpus" {
  bucket        = local.bucket_name
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_versioning" "kb_corpus" {
  bucket = aws_s3_bucket.kb_corpus.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kb_corpus" {
  bucket = aws_s3_bucket.kb_corpus.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "kb_corpus" {
  bucket = aws_s3_bucket.kb_corpus.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "kb_corpus" {
  bucket = aws_s3_bucket.kb_corpus.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Enforce TLS-only access
resource "aws_s3_bucket_policy" "kb_corpus_tls" {
  bucket = aws_s3_bucket.kb_corpus.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.kb_corpus.arn,
          "${aws_s3_bucket.kb_corpus.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Prefix structure for document organisation
resource "aws_s3_object" "prefix_runbooks" {
  bucket  = aws_s3_bucket.kb_corpus.id
  key     = "runbooks/.keep"
  content = ""
}

resource "aws_s3_object" "prefix_playbooks" {
  bucket  = aws_s3_bucket.kb_corpus.id
  key     = "playbooks/.keep"
  content = ""
}

resource "aws_s3_object" "prefix_architecture" {
  bucket  = aws_s3_bucket.kb_corpus.id
  key     = "architecture/.keep"
  content = ""
}
