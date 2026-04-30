output "state_bucket_name" {
  description = "S3 bucket name for Terraform state — set as GitHub variable TF_STATE_BUCKET"
  value       = aws_s3_bucket.tf_state.bucket
}

output "state_lock_table" {
  description = "DynamoDB table name for state locking — set as GitHub variable TF_LOCK_TABLE"
  value       = aws_dynamodb_table.tf_lock.name
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions — set as GitHub secret AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}
