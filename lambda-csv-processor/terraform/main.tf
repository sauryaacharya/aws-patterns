provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_s3_bucket" "csv_report_bucket" {
  bucket = "test-demo-csv-report"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"
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

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda-policy-attachment"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "chunking_lambda_handler" {
  function_name    = "chunking-handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "dist/index.handler"
  runtime          = "nodejs22.x"
  timeout          = 120
  memory_size      = 256
  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.chunk_queue.url
    }
  }
  filename         = "${path.module}/../lambda/chunk/chunk-lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/chunk/chunk-lambda.zip")
}

resource "aws_lambda_function" "chunk_processor_lambda_handler" {
  function_name    = "chunk-processor-handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.chunking_processor_lambda_zip.output_path
  source_code_hash = data.archive_file.chunking_processor_lambda_zip.output_base64sha256
}

data "archive_file" "chunking_processor_lambda_zip" {
  type       = "zip"
  source_dir = "${path.module}/../lambda/chunk-processor"
  output_path = "${path.module}/chunk-processor-lambda.zip"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.csv_report_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.chunking_lambda_handler.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chunking_lambda_handler.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.csv_report_bucket.arn
}

resource "aws_iam_policy" "lambda_sqs_s3_policy" {
  name        = "lambda-access-policy"
  description = "Lambda sqs and s3 policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ],
        Resource = aws_sqs_queue.chunk_queue.arn
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.csv_report_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_sqs_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_s3_policy.arn
}

resource "aws_sqs_queue" "chunk_queue" {
  name = "chunk-queue"
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn = aws_sqs_queue.chunk_queue.arn
  function_name    = aws_lambda_function.chunk_processor_lambda_handler.arn
  batch_size       = 10
  enabled          = true
  function_response_types = ["ReportBatchItemFailures"]
  depends_on = [
    aws_iam_role_policy_attachment.attach_lambda_sqs_policy
  ]
}

