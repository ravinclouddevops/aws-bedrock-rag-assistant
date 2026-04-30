locals {
  kb_role_arn  = var.bedrock_kb_role_arn != "" ? var.bedrock_kb_role_arn : aws_iam_role.bedrock_kb[0].arn
  create_role  = var.bedrock_kb_role_arn == ""
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# IAM Role — Bedrock Knowledge Base service role
# ---------------------------------------------------------------------------

resource "aws_iam_role" "bedrock_kb" {
  count = local.create_role ? 1 : 0

  name        = "${var.project_name}-kb-role-${var.environment}"
  description = "Service role for Bedrock Knowledge Base ${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockKBAssume"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_s3" {
  count = local.create_role ? 1 : 0

  name = "s3-corpus-access"
  role = aws_iam_role.bedrock_kb[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.kb_corpus.arn]
      },
      {
        Sid    = "S3GetObjects"
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.kb_corpus.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_bedrock_models" {
  count = local.create_role ? 1 : 0

  name = "bedrock-model-invoke"
  role = aws_iam_role.bedrock_kb[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockInvokeEmbedding"
        Effect = "Allow"
        Action = ["bedrock:InvokeModel"]
        Resource = [var.kb_embedding_model_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_secrets" {
  count = local.create_role ? 1 : 0

  name = "pinecone-secret-read"
  role = aws_iam_role.bedrock_kb[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [aws_secretsmanager_secret.pinecone_api_key.arn]
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Bedrock Knowledge Base
# ---------------------------------------------------------------------------

resource "aws_bedrockagent_knowledge_base" "rag_kb" {
  name        = "${var.project_name}-kb-${var.environment}"
  description = "Cloud operations knowledge base — runbooks, playbooks, architecture docs"
  role_arn    = local.kb_role_arn

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = var.kb_embedding_model_arn
    }
  }

  storage_configuration {
    type = "PINECONE"

    pinecone_configuration {
      connection_string      = "https://${pinecone_index.kb_vectors.host}"
      credentials_secret_arn = aws_secretsmanager_secret.pinecone_api_key.arn

      field_mapping {
        text_field     = "text"
        metadata_field = "metadata"
      }
    }
  }

  depends_on = [
    aws_iam_role_policy.bedrock_kb_s3,
    aws_iam_role_policy.bedrock_kb_bedrock_models,
    aws_iam_role_policy.bedrock_kb_secrets,
  ]
}

# ---------------------------------------------------------------------------
# Bedrock Knowledge Base Data Source — S3
# ---------------------------------------------------------------------------

resource "aws_bedrockagent_data_source" "s3_source" {
  name             = "${var.project_name}-s3-source"
  knowledge_base_id = aws_bedrockagent_knowledge_base.rag_kb.id
  description      = "S3 document corpus — runbooks, playbooks, architecture docs"

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn          = aws_s3_bucket.kb_corpus.arn
      inclusion_prefixes  = ["runbooks/", "playbooks/", "architecture/"]
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "HIERARCHICAL"

      hierarchical_chunking_configuration {
        level_configuration {
          max_tokens = 1500
        }
        level_configuration {
          max_tokens = 300
        }
        overlap_tokens = 60
      }
    }
  }
}
