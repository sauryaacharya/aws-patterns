# 🧩 AWS Serverless Patterns & Examples

This repository demonstrates common AWS serverless architecture patterns using Terraform and sample code. Each folder contains a self-contained example you can deploy and test locally using the AWS CLI and Terraform.

The goal is to make it easy to learn, build, and reuse proven event-driven architecture patterns on AWS.

## 📦 Available Patterns

| Pattern  | Description                         | Link                                                                                               |
|----------|-------------------------------------|----------------------------------------------------------------------------------------------------|
| S3 → Lambda  | Trigger Lambda on S3 upload events  | [**S3 → Lambda**](https://github.com/sauryaacharya/aws-patterns/tree/main/s3-lambda)               |
 | S3 → SQS → Lambda | S3 triggers SQS to invoke Lambda | [**S3 → SQS** → **Lambda**](https://github.com/sauryaacharya/aws-patterns/tree/main/s3-sqs-lambda) |

## 📌 Notes
- All examples use minimal configuration to focus on the core pattern.
- Designed for local development and learning.
- You are free to adapt and extend these for real-world use.