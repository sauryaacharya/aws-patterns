provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_dynamodb_table" "messages" {
  name           = "messages"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "messageId"
  attribute {
    name = "messageId"
    type = "S"
  }
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_stream_read" {
  name = "lambda-stream-read-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:DescribeStream",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:ListStreams"
      ]
      Resource = aws_dynamodb_table.messages.stream_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_stream_read_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_stream_read.arn
}


resource "aws_lambda_function" "stream_processor" {
  function_name    = "stream-processor"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "dist/index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../index.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = aws_dynamodb_table.messages.stream_arn
  function_name     = aws_lambda_function.stream_processor.arn
  starting_position = "LATEST"
  batch_size        = 100
  enabled           = true
  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["INSERT"]
      })
    }
  }
}
