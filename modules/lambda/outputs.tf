output "lambda_function_arn" {
  description = "Lambda Function ARN"
  value       = aws_lambda_function.api.arn
}

output "lambda_function_qualified_arn" {
  description = "Lambda Function qualified ARN"
  value       = aws_lambda_function.api.qualified_arn
}

output "lambda_function_version" {
  description = "Lambda function version"
  value       = aws_lambda_function.api.version
}

output "lambda_execution_iam_role_arn" {
  description = "Lambda execution IAM role ARN"
  value       = aws_iam_role.api.arn
}

output "lambda_cloudwatch_logs_log_group_name" {
  description = "Lambda CloudWatch Logs log group name"
  value       = aws_cloudwatch_log_group.api.name
}

output "lambda_function_url" {
  description = "Lambda Function URL"
  value       = aws_lambda_function_url.api.function_url
}

output "lambda_function_url_id" {
  description = "Lambda Function URL ID"
  value       = aws_lambda_function_url.api.url_id
}
