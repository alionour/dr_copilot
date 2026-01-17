# Backend Deployment Information

## Deployment Details

- **Deployment Date**: 2025-11-21
- **Region**: us-east-1
- **Stack Name**: dr-copilot-backend-prod
- **Deployment Time**: 89 seconds
- **Package Size**: 1.5 MB (optimized with esbuild)

## API Endpoint

**Base URL**: `https://hg4orotvf0.execute-api.us-east-1.amazonaws.com`

## Available Endpoints

### Health Check
- **URL**: `GET https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/`
- **Description**: Returns server status and timestamp

### Send Invitation
- **URL**: `POST https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/invitations`
- **Description**: Sends an invitation email via Amazon SES
- **Body**:
  ```json
  {
    "recipientEmail": "user@example.com",
    "recipientName": "John Doe",
    "clinicName": "Your Clinic Name",
    "role": "Doctor"
  }
  ```

### Send Notification
- **URL**: `POST https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/notifications`
- **Description**: Sends a push notification via Firebase Cloud Messaging
- **Body**:
  ```json
  {
    "userId": "firebase-user-id",
    "title": "Notification Title",
    "message": "Notification message"
  }
  ```

## Environment Variables (Configured in Doppler)

- ✅ `FIREBASE_SERVICE_ACCOUNT` - Firebase service account credentials
- ✅ `SES_FROM_EMAIL` - no-reply@drcopilot.com
- ✅ `APP_URL` - http://localhost:3000

## AWS Resources Created

- **Lambda Function**: `dr-copilot-backend-prod-api`
- **API Gateway**: HTTP API (v2)
- **CloudFormation Stack**: `dr-copilot-backend-prod`
- **IAM Role**: Auto-generated with SES and CloudWatch permissions

## Cost Estimate (Free Tier)

All resources are within AWS Free Tier limits:
- Lambda: 1M requests/month free
- API Gateway: 1M requests/month free (first 12 months)
- SES: 62,000 emails/month free when sending from Lambda
- CloudWatch Logs: 5GB free storage

## Notes

- **SES Email**: The email `no-reply@drcopilot.com` needs to be verified in Amazon SES before invitation emails will work
- **Optimization**: Deployment uses esbuild bundler to minimize package size (1.5 MB vs 16.6 MB)
- **Framework**: Serverless Framework v3 (no authentication required)
