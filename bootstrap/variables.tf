variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "bedrock-rag-assistant"
}

variable "github_org" {
  description = "GitHub organisation or username (e.g. ravinclouddevops)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g. aws-bedrock-rag-assistant)"
  type        = string
  default     = "aws-bedrock-rag-assistant"
}

variable "create_oidc_provider" {
  description = "Set false if your account already has a GitHub OIDC provider (e.g. from the landing zone project)"
  type        = bool
  default     = true
}
