# S3 to Eventbridge

This project demonstrates a serverless pattern where an object uploaded to an S3 bucket triggers a message to be sent to an EventBridge, which then invokes an AWS Lambda function to process the event.

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