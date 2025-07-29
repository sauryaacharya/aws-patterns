provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_sns_topic" "order_events" {
  name = "order-events-topic"
}

resource "aws_sqs_queue" "notification_queue" {
  name = "notification-queue"
}

resource "aws_sqs_queue" "shipping_queue" {
  name = "shipping-queue"
}

resource "aws_sqs_queue" "alert_queue" {
  name = "alert-queue"
}

resource "aws_sns_topic_subscription" "notification_sub" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notification_queue.arn
  raw_message_delivery = true
}

resource "aws_sns_topic_subscription" "shipping_sub" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.shipping_queue.arn
  raw_message_delivery = true
}

resource "aws_sns_topic_subscription" "alert_sub" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.alert_queue.arn
  raw_message_delivery = true
  filter_policy_scope = "MessageBody"

  filter_policy = jsonencode({
    totalAmount = [{
      numeric = [">", 10000]
    }]
  })
}

data "aws_iam_policy_document" "sqs_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = ["sqs:SendMessage"]

    resources = [
      aws_sqs_queue.notification_queue.arn,
      aws_sqs_queue.shipping_queue.arn,
      aws_sqs_queue.alert_queue.arn,
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.order_events.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "notification_policy" {
  queue_url = aws_sqs_queue.notification_queue.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}

resource "aws_sqs_queue_policy" "shipping_policy" {
  queue_url = aws_sqs_queue.shipping_queue.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}

resource "aws_sqs_queue_policy" "alert_policy" {
  queue_url = aws_sqs_queue.alert_queue.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
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

resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda-access-policy"
  description = "Lambda sqs and s3 policy"

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
        Resource = [
          aws_sqs_queue.notification_queue.arn,
          aws_sqs_queue.shipping_queue.arn,
          aws_sqs_queue.alert_queue.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_sqs_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

resource "aws_lambda_function" "notification_lambda_handler" {
  function_name    = "notification-handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.notification_lambda_zip.output_path
  source_code_hash = data.archive_file.notification_lambda_zip.output_base64sha256
}

resource "aws_lambda_function" "shipping_lambda_handler" {
  function_name    = "shipping-handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.shipping_lambda_zip.output_path
  source_code_hash = data.archive_file.shipping_lambda_zip.output_base64sha256
}

resource "aws_lambda_function" "alert_lambda_handler" {
  function_name    = "alert-handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.alert_lambda_zip.output_path
  source_code_hash = data.archive_file.alert_lambda_zip.output_base64sha256
}

data "archive_file" "notification_lambda_zip" {
  type       = "zip"
  source_dir = "${path.module}/../lambda/notification"
  output_path = "${path.module}/notification-lambda.zip"
}

data "archive_file" "shipping_lambda_zip" {
  type       = "zip"
  source_dir = "${path.module}/../lambda/shipping"
  output_path = "${path.module}/shipping-lambda.zip"
}

data "archive_file" "alert_lambda_zip" {
  type       = "zip"
  source_dir = "${path.module}/../lambda/alert"
  output_path = "${path.module}/alert-lambda.zip"
}

resource "aws_lambda_event_source_mapping" "notification_mapping" {
  event_source_arn = aws_sqs_queue.notification_queue.arn
  function_name    = aws_lambda_function.notification_lambda_handler.arn
  batch_size       = 10
}

resource "aws_lambda_event_source_mapping" "shipping_mapping" {
  event_source_arn = aws_sqs_queue.shipping_queue.arn
  function_name    = aws_lambda_function.shipping_lambda_handler.arn
  batch_size       = 10
}

resource "aws_lambda_event_source_mapping" "alert_mapping" {
  event_source_arn = aws_sqs_queue.alert_queue.arn
  function_name    = aws_lambda_function.alert_lambda_handler.arn
  batch_size       = 10
}
