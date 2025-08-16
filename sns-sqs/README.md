# SNS to SQS to Lambda

This project demonstrates a serverless pattern where a message is published to an SNS topic, which then fans out to multiple SQS queues to trigger dedicated lambda functions

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