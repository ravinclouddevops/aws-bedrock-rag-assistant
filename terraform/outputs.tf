output "s3_bucket_name" {
  description = "Name of the S3 document corpus bucket"
  value       = aws_s3_bucket.kb_corpus.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 document corpus bucket"
  value       = aws_s3_bucket.kb_corpus.arn
}

output "opensearch_collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = aws_opensearchserverless_collection.kb_vectors.collection_endpoint
}

output "opensearch_collection_arn" {
  description = "ARN of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.kb_vectors.arn
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
