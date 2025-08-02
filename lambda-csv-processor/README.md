# Lambda CSV Processor

This project demonstrates a serverless pattern where an AWS Lambda function is automatically triggered by an S3 object upload. The Lambda streams and chunks large CSV files, sending batched messages to an SQS queue for downstream processing. The infrastructure is provisioned using Terraform.

## 📋 Prerequisites

- ✅ AWS CLI installed

- ✅ AWS credentials configured via aws configure (ensure access to S3 and Lambda)

```
aws configure
```

## 🚀 Deployment Steps

- Building Chunking Lambda
```
cd lambda/chunk
make build
```
- Run terraform
```
cd terraform
terraform init
terraform apply
```