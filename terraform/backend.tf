terraform {
  backend "s3" {
    # Bucket, key, region, and dynamodb_table are injected at init time:
    #   terraform init \
    #     -backend-config="bucket=$TF_STATE_BUCKET" \
    #     -backend-config="key=bedrock-rag-assistant/dev/terraform.tfstate" \
    #     -backend-config="region=us-east-1" \
    #     -backend-config="dynamodb_table=$TF_LOCK_TABLE" \
    #     -backend-config="encrypt=true"
    #
    # Values come from bootstrap/outputs (run once manually).
    # In CI they are sourced from GitHub repository variables.
  }
}
