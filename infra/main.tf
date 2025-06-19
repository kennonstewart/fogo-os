# firehouse_infra/main.tf

provider "aws" {
  region = "us-east-2"
}

# 1. Create an S3 bucket for optional frame storage
resource "aws_s3_bucket" "frame_store" {
  bucket = "firehouse-frame-archive-${random_id.suffix.hex}"
  force_destroy = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

# 2. Create a DynamoDB table for verification flags
resource "aws_dynamodb_table" "verification_flags" {
  name           = "verification_flags"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }
}

# 3. IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "firehouse_lambda_exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 4. Lambda Function for facial recognition (placeholder)
resource "aws_lambda_function" "frame_processor" {
  function_name = "firehouse_frame_processor"
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  image_uri     = "123456789012.dkr.ecr.us-east-2.amazonaws.com/firehouse-frame-processor:latest"

  environment {
    variables = {
      FRAME_BUCKET = aws_s3_bucket.frame_store.bucket
      FLAG_TABLE   = aws_dynamodb_table.verification_flags.name
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_logs]
}

# 5. API Gateway for receiving POSTed frames
resource "aws_apigatewayv2_api" "http_api" {
  name          = "firehouse-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.frame_processor.invoke_arn
}

resource "aws_apigatewayv2_route" "post_stream" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /stream-frame"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.frame_processor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
