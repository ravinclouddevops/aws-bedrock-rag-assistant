# ---------------------------------------------------------------------------
# Secrets Manager — Pinecone API key for Bedrock Knowledge Base
#
# Bedrock KB requires a Secrets Manager ARN for third-party vector stores.
# Terraform creates the secret shell only; the actual API key value is
# written by CI (terraform-apply.yml) from the PINECONE_API_KEY GitHub secret.
# This keeps the key out of Terraform state entirely.
#
# Cost: $0.40/month after the 30-day free trial.
# ---------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "pinecone_api_key" {
  name                    = "${var.project_name}-pinecone-key-${var.environment}"
  description             = "Pinecone API key consumed by Bedrock Knowledge Base"
  recovery_window_in_days = 0 # immediate deletion on destroy — acceptable for dev
}
