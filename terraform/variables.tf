variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "bedrock-rag-assistant"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "kb_embedding_model_arn" {
  description = "Bedrock model ARN for embeddings (Titan Embeddings V2)"
  type        = string
  default     = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
}

variable "pinecone_index_name" {
  description = "Pinecone index name for the KB vector store"
  type        = string
  default     = "bedrock-rag-kb"
}

variable "titan_embedding_dimensions" {
  description = "Titan Embeddings V2 output dimensions — must match the Pinecone index"
  type        = number
  default     = 1024
}

variable "bedrock_kb_role_arn" {
  description = "Optional: bring-your-own IAM role ARN for the Bedrock Knowledge Base. If empty, one is created."
  type        = string
  default     = ""
}
