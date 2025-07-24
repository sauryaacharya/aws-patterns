provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_s3_bucket" "file_upload_bucket" {
  bucket = "s3-eventbridge-pattern-demo"
}

resource "aws_s3_object" "incoming_folder" {
  bucket = aws_s3_bucket.file_upload_bucket.id
  key    = "incoming/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "outgoing_folder" {
  bucket = aws_s3_bucket.file_upload_bucket.id
  key    = "outgoing/"
  content_type = "application/x-directory"
}

resource "aws_iam_role" "lambda_exec" {
  name = "s3-eb-lambda-exec-role"
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

resource "aws_lambda_function" "incoming_file_lambda_handler" {
  function_name    = "incoming-file-handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.incoming_lambda_zip.output_path
  source_code_hash = data.archive_file.outgoing_lambda_zip.output_base64sha256
}

resource "aws_lambda_function" "outgoing_file_lambda_handler" {
  function_name    = "outgoing-file-handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.outgoing_lambda_zip.output_path
  source_code_hash = data.archive_file.outgoing_lambda_zip.output_base64sha256
}

data "archive_file" "incoming_lambda_zip" {
  type       = "zip"
  source_dir = "${path.module}/../lambda/incoming"
  output_path = "${path.module}/incoming-lambda.zip"
}

data "archive_file" "outgoing_lambda_zip" {
  type       = "zip"
  source_dir = "${path.module}/../lambda/outgoing"
  output_path = "${path.module}/outgoing-lambda.zip"
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.file_upload_bucket.id
  eventbridge = true
}

resource "aws_cloudwatch_event_rule" "outgoing_rule" {
  name        = "s3-outgoing-rule"
  description = "Trigger Lambda for files in outgoing/ folder"

  event_pattern = jsonencode({
    source = ["aws.s3"],
    detail-type = ["Object Created"]
    detail = {
      "bucket" = {
        "name" = [aws_s3_bucket.file_upload_bucket.id]
      }
      "object" = {
        "key" = [{
          "prefix": "outgoing/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_rule" "incoming_rule" {
  name        = "s3-incoming-rule"
  description = "Trigger Lambda for files in incoming/ folder"

  event_pattern = jsonencode({
    source = ["aws.s3"],
    detail-type = ["Object Created"]
    detail = {
      "bucket" = {
        "name" = [aws_s3_bucket.file_upload_bucket.id]
      }
      "object" = {
        "key" = [{
          "prefix": "incoming/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "incoming_target" {
  rule      = aws_cloudwatch_event_rule.incoming_rule.name
  arn       = aws_lambda_function.incoming_file_lambda_handler.arn
}

resource "aws_cloudwatch_event_target" "outgoing_target" {
  rule      = aws_cloudwatch_event_rule.outgoing_rule.name
  arn       = aws_lambda_function.outgoing_file_lambda_handler.arn
}

resource "aws_lambda_permission" "incoming_permission" {
  statement_id  = "AllowExecutionFromEventBridgeIncoming"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incoming_file_lambda_handler.id
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.incoming_rule.arn
}

resource "aws_lambda_permission" "outgoing_permission" {
  statement_id  = "AllowExecutionFromEventBridgeOutgoing"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.outgoing_file_lambda_handler.id
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.outgoing_rule.arn
}
