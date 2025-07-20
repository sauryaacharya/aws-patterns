# S3 Event to Lambda

This project demonstrates a serverless pattern where an AWS Lambda function is automatically triggered in response to an object being uploaded to an S3 bucket. The infrastructure is provisioned using Terraform.

## 📋 Prerequisites

- ✅ AWS CLI installed

- ✅ AWS credentials configured via aws configure (ensure access to S3 and Lambda)

```
aws configure
```

## 🚀 Deployment Steps
```
cd terraform
terraform init
terraform apply
```