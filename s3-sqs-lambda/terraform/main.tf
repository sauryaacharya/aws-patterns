provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_s3_bucket" "file_upload_bucket" {
  bucket = "s3-sqs-pattern-demo"
}

resource "aws_iam_role" "lambda_exec" {
  name = "s3-sqs-lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "s3_lambda_handler_logs" {
  name       = "sqs-lambda-logs"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda-sqs-access"
  description = "Allow Lambda to poll and delete messages from SQS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.file_events_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_sqs_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

resource "aws_lambda_function" "sqs_lambda_handler" {
  function_name    = "sqs-lambda-handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "dist/index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../index.js"
  output_path = "${path.module}/sqs-lambda.zip"
}

resource "aws_sqs_queue" "file_events_queue" {
  name = "file-events-queue"
}

resource "aws_sqs_queue_policy" "allow_s3_send_message" {
  queue_url = aws_sqs_queue.file_events_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      },
      Action = "sqs:SendMessage",
      Resource = aws_sqs_queue.file_events_queue.arn,
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_s3_bucket.file_upload_bucket.arn
        }
      }
    }]
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.file_upload_bucket.id

  queue {
    queue_arn = aws_sqs_queue.file_events_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue.file_events_queue]
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn = aws_sqs_queue.file_events_queue.arn
  function_name    = aws_lambda_function.sqs_lambda_handler.arn
  batch_size       = 10
  enabled          = true
}
