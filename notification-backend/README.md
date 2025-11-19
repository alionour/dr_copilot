# DR Copilot Notification Backend - AWS Lambda

This AWS Lambda function sends push notifications to dr_copilot mobile app users via Firebase Cloud Messaging (FCM).

## 🎯 Features

- ✅ Sends FCM push notifications
- ✅ Handles invalid/expired tokens
- ✅ CORS enabled
- ✅ Production-ready error handling
- ✅ Logging for monitoring
- ✅ Auto-scales (AWS Lambda)

## 📦 Setup

### Prerequisites

1. **AWS Account** (free tier available)
2. **AWS CLI** installed and configured
3. **Node.js** installed (v18 or later)
4. **Firebase Service Account Key**

### Step 1: Install Dependencies

```bash
cd notification-backend
npm install
```

### Step 2: Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (drcopilot-bfc9e)
3. Go to **Project Settings** → **Service Accounts**
4. Click **"Generate New Private Key"**
5. Download the JSON file
6. Save as `serviceAccountKey.json` (keep this secure!)

### Step 3: Package the Function

```bash
# Windows
npm run package-windows

# Mac/Linux
npm run package
```

This creates `function.zip` ready for upload to AWS Lambda.

## 🚀 Deployment

### Method 1: AWS Console (Easiest - 15 minutes)

#### Step 1: Create Lambda Function

1. Go to [AWS Lambda Console](https://console.aws.amazon.com/lambda/)
2. Click **"Create function"**
3. Choose **"Author from scratch"**
4. Settings:
   - **Function name:** `dr-copilot-notifications`
   - **Runtime:** Node.js 18.x
   - **Architecture:** x86_64
5. Click **"Create function"**

#### Step 2: Upload Code

1. In the function page, go to **"Code" tab**
2. Click **"Upload from"** → **".zip file"**
3. Select `function.zip`
4. Click **"Save"**

#### Step 3: Add Environment Variables

1. Go to **"Configuration" tab** → **"Environment variables"**
2. Click **"Edit"** → **"Add environment variable"**
3. Add:
   - **Key:** `FIREBASE_SERVICE_ACCOUNT`
   - **Value:** Paste the entire content of your `serviceAccountKey.json`
4. Click **"Save"**

#### Step 4: Increase Timeout (Optional but Recommended)

1. Go to **"Configuration" tab** → **"General configuration"**
2. Click **"Edit"**
3. Set **Timeout:** 30 seconds
4. Click **"Save"**

#### Step 5: Create API Gateway

1. Go to [API Gateway Console](https://console.aws.amazon.com/apigateway/)
2. Click **"Create API"**
3. Choose **"HTTP API"** → **"Build"**
4. Settings:
   - **API name:** `dr-copilot-notifications-api`
   - **Integration type:** Lambda
   - **Lambda function:** Select `dr-copilot-notifications`
   - **Method:** POST
   - **Resource path:** `/send-notification`
5. Click **"Next"** → **"Next"** → **"Create"**

#### Step 6: Get Your API URL

After creating, you'll see something like:
```
https://abc123xyz.execute-api.us-east-1.amazonaws.com/send-notification
```

**Save this URL!** You'll use it in your Flutter app.

### Method 2: AWS CLI (Advanced - 5 minutes)

#### Prerequisites

```bash
# Configure AWS CLI (one-time setup)
aws configure
# Enter:
#   AWS Access Key ID: [Your key]
#   AWS Secret Access Key: [Your secret]
#   Default region name: us-east-1
#   Default output format: json
```

#### Create IAM Role (One-time)

```bash
# Create trust policy
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create role
aws iam create-role \
  --role-name dr-copilot-lambda-role \
  --assume-role-policy-document file://trust-policy.json

# Attach basic Lambda execution policy
aws iam attach-role-policy \
  --role-name dr-copilot-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Wait for role to be ready
sleep 10
```

#### Deploy Function

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create Lambda function
aws lambda create-function \
  --function-name dr-copilot-notifications \
  --runtime nodejs18.x \
  --role arn:aws:iam::${ACCOUNT_ID}:role/dr-copilot-lambda-role \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --timeout 30 \
  --memory-size 256

# Add environment variable (replace with your serviceAccountKey.json content)
aws lambda update-function-configuration \
  --function-name dr-copilot-notifications \
  --environment "Variables={FIREBASE_SERVICE_ACCOUNT=$(cat serviceAccountKey.json | jq -c .)}"

# Create API Gateway
API_ID=$(aws apigatewayv2 create-api \
  --name dr-copilot-notifications-api \
  --protocol-type HTTP \
  --target arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:dr-copilot-notifications \
  --query ApiId \
  --output text)

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
  --function-name dr-copilot-notifications \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:${API_ID}/*/*"

# Get your API URL
echo "Your API URL:"
echo "https://${API_ID}.execute-api.us-east-1.amazonaws.com/send-notification"
```

## 🧪 Testing

### Test with curl

```bash
curl -X POST https://YOUR-API-URL.execute-api.us-east-1.amazonaws.com/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "YOUR_USER_ID",
    "title": "Test Notification",
    "message": "This is a test from AWS Lambda!",
    "type": "system"
  }'
```

### Test from AWS Console

1. Go to Lambda function
2. Click **"Test" tab**
3. Create new test event:

```json
{
  "httpMethod": "POST",
  "body": "{\"userId\":\"YOUR_USER_ID\",\"title\":\"Test\",\"message\":\"Hello from Lambda!\"}"
}
```

4. Click **"Test"**

### Expected Response (Success)

```json
{
  "statusCode": 200,
  "body": "{\"success\":true,\"messageId\":\"...\",\"userId\":\"...\",\"timestamp\":\"...\"}"
}
```

## 📊 Monitoring

### View Logs

```bash
# AWS CLI
aws logs tail /aws/lambda/dr-copilot-notifications --follow

# Or in AWS Console:
# CloudWatch → Log groups → /aws/lambda/dr-copilot-notifications
```

### Metrics to Monitor

- **Invocations:** How many times function called
- **Errors:** Failed executions
- **Duration:** Response time
- **Throttles:** Rate limit hits

## 💰 Cost Estimation

### AWS Lambda Free Tier

- **1 Million requests/month FREE (forever)**
- **400,000 GB-seconds compute FREE**

### After Free Tier

| Notifications/Day | Requests/Month | Cost/Month |
|-------------------|----------------|------------|
| 1,000 | 30,000 | **$0** |
| 5,000 | 150,000 | **$0** |
| 10,000 | 300,000 | **$0** |
| 50,000 | 1,500,000 | ~$2-3 |
| 100,000 | 3,000,000 | ~$6-8 |

**For most apps, this will stay FREE!** 🎉

## 🔧 Updating the Function

### Update Code

```bash
# Make changes to index.js
# Re-package
npm run package-windows

# Upload via AWS CLI
aws lambda update-function-code \
  --function-name dr-copilot-notifications \
  --zip-file fileb://function.zip

# Or upload via AWS Console → Lambda → Upload .zip
```

### Update Environment Variables

```bash
aws lambda update-function-configuration \
  --function-name dr-copilot-notifications \
  --environment "Variables={FIREBASE_SERVICE_ACCOUNT=$(cat serviceAccountKey.json | jq -c .)}"
```

## 🐛 Troubleshooting

### Error: "Firebase initialization failed"

- Check environment variable `FIREBASE_SERVICE_ACCOUNT` is set correctly
- Verify JSON is valid (use jsonlint.com)

### Error: "User not found"

- Verify `userId` exists in Firestore `users` collection

### Error: "No FCM token found"

- User needs to sign in to the app to register FCM token
- Check Firestore: `users/{userId}/fcmToken` field exists

### Error: "FCM token is invalid"

- Token automatically removed from Firestore
- User needs to sign in again

### Function Times Out

- Increase timeout: Configuration → General configuration → Timeout (30s recommended)

### Cold Start Delays

- First invocation may take 1-2 seconds
- Subsequent calls are faster
- Consider AWS Lambda Provisioned Concurrency for production (costs extra)

## 🔒 Security

### Firestore Rules

Ensure your Firestore has proper rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### IAM Permissions

Lambda function should only have:
- Basic execution role (CloudWatch Logs)
- No additional AWS permissions needed (Firebase handles FCM)

## 📚 Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)

## 🆘 Support

For issues:
1. Check CloudWatch Logs
2. Verify Firebase credentials
3. Test with simple curl command
4. Check AWS Lambda quotas

## 📝 Next Steps

After deployment:
1. ✅ Test with curl
2. ✅ Update Flutter app with API URL
3. ✅ Test from Flutter app
4. ✅ Monitor in CloudWatch
5. ✅ Set up alarms (optional)

**Your backend is ready!** 🚀
