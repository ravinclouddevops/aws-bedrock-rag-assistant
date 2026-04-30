# ---------------------------------------------------------------------------
# Pinecone Serverless Index — free-tier vector store for Bedrock Knowledge Base
#
# Free tier: 1 serverless index, no time limit, ~5GB storage.
# API key is read from PINECONE_API_KEY env var by the pinecone provider.
# ---------------------------------------------------------------------------

resource "pinecone_index" "kb_vectors" {
  name      = var.pinecone_index_name
  dimension = var.titan_embedding_dimensions
  metric    = "cosine"

  spec = {
    serverless = {
      cloud  = "aws"
      region = var.aws_region
    }
  }
}
