output "s3_bucket_name" {
  description = "Name of the S3 document corpus bucket"
  value       = aws_s3_bucket.kb_corpus.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 document corpus bucket"
  value       = aws_s3_bucket.kb_corpus.arn
}


output "pinecone_index_host" {
  description = "Pinecone index host — used as Bedrock KB connection string"
  value       = pinecone_index.kb_vectors.host
}

output "pinecone_secret_arn" {
  description = "Secrets Manager ARN for the Pinecone API key — used by CI to populate the key"
  value       = aws_secretsmanager_secret.pinecone_api_key.arn
}

output "bedrock_kb_id" {
  description = "Bedrock Knowledge Base ID"
  value       = aws_bedrockagent_knowledge_base.rag_kb.id
}

output "bedrock_kb_arn" {
  description = "ARN of the Bedrock Knowledge Base"
  value       = aws_bedrockagent_knowledge_base.rag_kb.arn
}

output "bedrock_data_source_id" {
  description = "Bedrock Knowledge Base data source ID"
  value       = aws_bedrockagent_data_source.s3_source.data_source_id
}

output "bedrock_kb_role_arn" {
  description = "IAM role ARN used by the Bedrock Knowledge Base"
  value       = local.kb_role_arn
}
