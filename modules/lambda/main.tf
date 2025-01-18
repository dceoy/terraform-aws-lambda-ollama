resource "aws_lambda_function" "api" {
  function_name                  = local.lambda_function_name
  description                    = local.lambda_function_name
  role                           = aws_iam_role.api.arn
  package_type                   = "Image"
  image_uri                      = local.lambda_image_uri
  architectures                  = var.lambda_architectures
  memory_size                    = var.lambda_memory_size
  timeout                        = var.lambda_timeout
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions
  logging_config {
    log_group             = aws_cloudwatch_log_group.api.name
    log_format            = var.lambda_logging_config_log_format
    application_log_level = var.lambda_logging_config_log_format == "Text" ? null : var.lambda_logging_config_application_log_level
    system_log_level      = var.lambda_logging_config_log_format == "Text" ? null : var.lambda_logging_config_system_log_level
  }
  tracing_config {
    mode = var.lambda_tracing_config_mode
  }
  dynamic "ephemeral_storage" {
    for_each = var.lambda_ephemeral_storage_size != null ? [true] : []
    content {
      size = var.lambda_ephemeral_storage_size
    }
  }
  dynamic "image_config" {
    for_each = length(var.lambda_image_config_entry_point) > 0 || length(var.lambda_image_config_command) > 0 || var.lambda_image_config_working_directory != null ? [true] : []
    content {
      entry_point       = var.lambda_image_config_entry_point
      command           = var.lambda_image_config_command
      working_directory = var.lambda_image_config_working_directory
    }
  }
  dynamic "environment" {
    for_each = length(keys(var.lambda_environment_variables)) > 0 ? [true] : []
    content {
      variables = var.lambda_environment_variables
    }
  }
  tags = {
    Name       = local.lambda_function_name
    SystemName = var.system_name
    EnvType    = var.env_type
  }
}

# trivy:ignore:avd-aws-0017
resource "aws_cloudwatch_log_group" "api" {
  name              = "/${var.system_name}/${var.env_type}/lambda/${local.lambda_function_name}"
  retention_in_days = var.cloudwatch_logs_retention_in_days
  kms_key_id        = var.kms_key_arn
  tags = {
    Name       = "/${var.system_name}/${var.env_type}/lambda/${local.lambda_function_name}"
    SystemName = var.system_name
    EnvType    = var.env_type
  }
}

resource "aws_lambda_provisioned_concurrency_config" "api" {
  count                             = var.lambda_provisioned_concurrent_executions > -1 ? 1 : 0
  function_name                     = aws_lambda_function.api.function_name
  qualifier                         = aws_lambda_function.api.version == "$LATEST" ? null : aws_lambda_function.api.version
  provisioned_concurrent_executions = var.lambda_provisioned_concurrent_executions
}

resource "aws_lambda_function_url" "api" {
  function_name      = aws_lambda_function.api.function_name
  qualifier          = aws_lambda_function.api.version == "$LATEST" ? null : aws_lambda_function.api.version
  authorization_type = var.lambda_function_url_authorization_type
  invoke_mode        = var.lambda_function_url_invoke_mode
  dynamic "cors" {
    for_each = length(var.lambda_function_url_cors) > 0 ? [true] : []
    content {
      allow_credentials = lookup(var.lambda_function_url_cors, "allow_credentials", null)
      allow_headers     = lookup(var.lambda_function_url_cors, "allow_headers", null)
      allow_methods     = lookup(var.lambda_function_url_cors, "allow_methods", null)
      allow_origins     = lookup(var.lambda_function_url_cors, "allow_origins", null)
      expose_headers    = lookup(var.lambda_function_url_cors, "expose_headers", null)
      max_age           = lookup(var.lambda_function_url_cors, "max_age", null)
    }
  }
}

resource "aws_iam_role" "api" {
  name                  = "${var.system_name}-${var.env_type}-lambda-execution-iam-role"
  description           = "Lambda execution IAM role"
  force_detach_policies = var.iam_role_force_detach_policies
  path                  = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaServiceToAssumeRole"
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name       = "${var.system_name}-${var.env_type}-lambda-execution-iam-role"
    SystemName = var.system_name
    EnvType    = var.env_type
  }
}

resource "aws_iam_role_policy_attachments_exclusive" "api" {
  role_name = aws_iam_role.api.name
  policy_arns = compact([
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    var.s3_iam_policy_arn
  ])
}

resource "aws_iam_role_policy" "api" {
  name = "${var.system_name}-${var.env_type}-lambda-execution-iam-role-policy"
  role = aws_iam_role.api.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid      = "AllowDescribeLogGroups"
          Effect   = "Allow"
          Action   = ["logs:DescribeLogGroups"]
          Resource = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:*"]
        },
        {
          Sid    = "AllowLogStreamAccess"
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ]
          Resource = ["${aws_cloudwatch_log_group.api.arn}:*"]
        }
      ],
      (
        var.kms_key_arn != null ? [
          {
            Sid      = "AllowKMSAccess"
            Effect   = "Allow"
            Action   = ["kms:GenerateDataKey"]
            Resource = [var.kms_key_arn]
          }
        ] : []
      )
    )
  })
}
