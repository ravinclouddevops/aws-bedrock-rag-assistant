# ---------------------------------------------------------------------------
# Secrets Manager — Pinecone API key shell
#
# The secret VALUE is never written by Terraform. CI injects it via
# `aws secretsmanager put-secret-value` after apply, keeping the key
# out of Terraform state. See .github/workflows/terraform-apply.yml.
# ---------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "pinecone_api_key" {
  name        = "${var.project_name}-pinecone-key-${var.environment}"
  description = "Pinecone API key for Bedrock Knowledge Base (value injected by CI, never stored in Terraform state)"

  # 0 = force-delete immediately (safe for dev); prod uses 30-day recovery window
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
}
