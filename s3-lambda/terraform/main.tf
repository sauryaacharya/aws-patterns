provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_s3_bucket" "file_upload_bucket" {
  bucket = "s3-lambda-pattern-demo"
}

resource "aws_iam_role" "lambda_exec" {
  name = "s3-lambda-exec-role"
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
  name       = "lambda_logs"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "s3_lambda_handler" {
  function_name    = "s3_lambda_handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "dist/index.handler"
  runtime          = "nodejs22.x"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../index.js"
  output_path = "${path.module}/lambda.zip"
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.file_upload_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_lambda_handler.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_lambda_handler.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.file_upload_bucket.arn
}