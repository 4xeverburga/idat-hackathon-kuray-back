provider "aws" {
  region  = "us-east-1"
  profile = "protecso"
}

# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name               = "get_pests_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for DynamoDB Admin
resource "aws_iam_policy" "dynamodb_admin_policy" {
  name        = "get_pests_dynamodb_admin"
  description = "Policy for Lambda to access DynamoDB"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "dynamodb:*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_admin_policy.arn
}

# Lambda Function
resource "aws_lambda_function" "get_pests" {
  function_name = "get_pests"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = "get_pests.zip"

  # Increment resources
  memory_size   = 512  # Memory size in MB
  timeout       = 30   # Timeout in seconds

  environment {
    variables = {
      # Add your environment variables here
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "kuray_dev" {
  name          = "kuray_dev"
  protocol_type = "HTTP"
}

# Lambda Integration with API Gateway
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.kuray_dev.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.get_pests.arn
  payload_format_version = "2.0"
}

# Route for GET /pests
resource "aws_apigatewayv2_route" "get_pests_route" {
  api_id    = aws_apigatewayv2_api.kuray_dev.id
  route_key = "GET /pest"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Deploy the API Gateway
resource "aws_apigatewayv2_stage" "kuray_stage" {
  api_id      = aws_apigatewayv2_api.kuray_dev.id
  name        = "dev"
  auto_deploy = true
}

# Permission for API Gateway to Invoke Lambda
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_pests.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.kuray_dev.execution_arn}/*/*"
}

# Outputs
output "api_gateway_endpoint" {
  description = "The endpoint for the API Gateway"
  value       = "${aws_apigatewayv2_stage.kuray_stage.invoke_url}"
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.get_pests.function_name
}

output "lambda_execution_role" {
  description = "The IAM Role ARN for the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}
