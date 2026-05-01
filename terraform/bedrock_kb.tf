# ---------------------------------------------------------------------------
# Bedrock Knowledge Base — Pinecone vector store backend
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# IAM Role — Bedrock Knowledge Base service principal
# Conditionally created: skipped if var.bedrock_kb_role_arn is supplied.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "bedrock_kb" {
  count = var.bedrock_kb_role_arn == "" ? 1 : 0
  name  = "${var.project_name}-kb-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "BedrockAssume"
      Effect = "Allow"
      Principal = {
        Service = "bedrock.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      # Prevents confused-deputy attacks by scoping to this account
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}

locals {
  kb_role_arn = var.bedrock_kb_role_arn != "" ? var.bedrock_kb_role_arn : aws_iam_role.bedrock_kb[0].arn
}

resource "aws_iam_role_policy" "bedrock_kb_s3" {
  count = var.bedrock_kb_role_arn == "" ? 1 : 0
  name  = "s3-corpus-read"
  role  = aws_iam_role.bedrock_kb[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "S3Read"
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.kb_corpus.arn,
        "${aws_s3_bucket.kb_corpus.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_embed" {
  count = var.bedrock_kb_role_arn == "" ? 1 : 0
  name  = "bedrock-embed"
  role  = aws_iam_role.bedrock_kb[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "BedrockEmbed"
      Effect   = "Allow"
      Action   = "bedrock:InvokeModel"
      Resource = [var.kb_embedding_model_arn]
    }]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_secrets" {
  count = var.bedrock_kb_role_arn == "" ? 1 : 0
  name  = "pinecone-secret-read"
  role  = aws_iam_role.bedrock_kb[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "SecretsRead"
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = [aws_secretsmanager_secret.pinecone_api_key.arn]
    }]
  })
}

# ---------------------------------------------------------------------------
# Bedrock Knowledge Base
# ---------------------------------------------------------------------------

resource "aws_bedrockagent_knowledge_base" "rag_kb" {
  name     = "${var.project_name}-kb-${var.environment}"
  role_arn = local.kb_role_arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = var.kb_embedding_model_arn
    }
  }

  storage_configuration {
    type = "PINECONE"
    pinecone_configuration {
      # Pinecone provider exposes host without scheme
      connection_string      = "https://${pinecone_index.kb_vectors.host}"
      credentials_secret_arn = aws_secretsmanager_secret.pinecone_api_key.arn

      field_mapping {
        metadata_field = "metadata"
        text_field     = "text"
      }
    }
  }

  # IAM policies must exist before Bedrock validates the KB role
  depends_on = [
    aws_iam_role_policy.bedrock_kb_s3,
    aws_iam_role_policy.bedrock_kb_embed,
    aws_iam_role_policy.bedrock_kb_secrets,
  ]
}

# ---------------------------------------------------------------------------
# Data source — S3 corpus synced into the Knowledge Base
# ---------------------------------------------------------------------------

resource "aws_bedrockagent_data_source" "s3_source" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.rag_kb.id
  name              = "${var.project_name}-s3-docs"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.kb_corpus.arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        # 300 tokens ≈ ~1 runbook section; 20% overlap preserves cross-chunk context
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}
