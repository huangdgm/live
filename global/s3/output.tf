# The value of outputs are stored in the state file from which you can query information via terraform_remote_state resource.

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the s3 bucket"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform-locks.name
  description = "The name of the DynamoDB table"
}
