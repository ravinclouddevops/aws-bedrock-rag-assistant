locals {
  collection_name = "${var.project_name}-${var.environment}"
  index_name      = "bedrock-kb-index"

  # Caller identity used to seed the data access policy
  caller_arn = data.aws_caller_identity.current.arn
}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# OpenSearch Serverless — Vector store for Knowledge Base embeddings
# ---------------------------------------------------------------------------

# Encryption policy — AWS-managed key is fine for dev; swap to CMK for prod
resource "aws_opensearchserverless_security_policy" "encryption" {
  name        = "${local.collection_name}-enc"
  type        = "encryption"
  description = "Encryption policy for ${local.collection_name} vector collection"

  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${local.collection_name}"]
      }
    ]
    AWSOwnedKey = true
  })
}

# Network policy — private (VPC endpoint or service-to-service only)
resource "aws_opensearchserverless_security_policy" "network" {
  name        = "${local.collection_name}-net"
  type        = "network"
  description = "Network policy for ${local.collection_name} vector collection"

  # AllowFromPublic=false keeps the collection off the public internet.
  # Bedrock accesses it via the service network (SourceVPCEs not required
  # when the caller is a Bedrock service principal).
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${local.collection_name}"]
        },
        {
          ResourceType = "dashboard"
          Resource     = ["collection/${local.collection_name}"]
        }
      ]
      AllowFromPublic = false
    }
  ])
}

# Data access policy — grants Bedrock KB role and the deploying identity full access
resource "aws_opensearchserverless_access_policy" "kb_access" {
  name        = "${local.collection_name}-access"
  type        = "data"
  description = "Data access for Bedrock KB role and operator"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource     = ["index/${local.collection_name}/*"]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument",
            "aoss:UpdateIndex"
          ]
        },
        {
          ResourceType = "collection"
          Resource     = ["collection/${local.collection_name}"]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DescribeCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        }
      ]
      Principal = [
        local.kb_role_arn,
        local.caller_arn
      ]
    }
  ])

  depends_on = [aws_iam_role.bedrock_kb]
}

# Vector collection
resource "aws_opensearchserverless_collection" "kb_vectors" {
  name        = local.collection_name
  type        = "VECTORSEARCH"
  description = "Vector store for ${var.project_name} Bedrock Knowledge Base"

  standby_replicas = var.opensearch_standby_replicas == 0 ? "DISABLED" : "ENABLED"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.kb_access,
  ]
}
