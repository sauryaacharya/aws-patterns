# DynamoDB Streams to Lambda

This project demonstrates a serverless pattern where an AWS Lambda function is automatically triggered in response to changes in a DynamoDB table via DynamoDB Streams. The infrastructure is provisioned using Terraform.

## 📋 Prerequisites

- ✅ AWS CLI installed

- ✅ AWS credentials configured via aws configure

```
aws configure
```

## 🚀 Deployment Steps
```
cd terraform
terraform init
terraform apply
```