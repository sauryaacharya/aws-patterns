# S3 Event to SQS to Lambda

This project demonstrates a serverless pattern where an object uploaded to an S3 bucket triggers a message to be sent to an Amazon SQS queue, which then invokes an AWS Lambda function to process the event.

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