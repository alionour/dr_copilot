# 🚀 Quick Start: Deploy to AWS Lambda in 15 Minutes

## ✅ What You Have Now

All files are ready in `notification-backend/` folder:
- ✅ `index.js` - Lambda function code
- ✅ `package.json` - Dependencies
- ✅ `function.zip` - Ready to upload package
- ✅ `node_modules/` - All dependencies installed

## 📋 Next Steps

### Step 1: Get Firebase Service Account Key (5 minutes)

1. Go to https://console.firebase.google.com/
2. Select project: **drcopilot-bfc9e**
3. Click ⚙️ → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **"Generate New Private Key"**
6. Download the JSON file
7. **IMPORTANT:** Save it securely (you'll need the content)

### Step 2: Create AWS Lambda Function (5 minutes)

1. Go to https://console.aws.amazon.com/lambda/
2. Click **"Create function"**
3. Settings:
   - Function name: `dr-copilot-notifications`
   - Runtime: **Node.js 18.x**
   - Architecture: **x86_64**
4. Click **"Create function"**

### Step 3: Upload Code (2 minutes)

1. In Lambda function page:
   - Go to **"Code" tab**
   - Click **"Upload from"** → **".zip file"**
   - Select `function.zip` from `notification-backend/` folder
   - Click **"Save"**

### Step 4: Add Firebase Credentials (3 minutes)

1. In Lambda function page:
   - Go to **"Configuration" tab**
   - Click **"Environment variables"**
   - Click **"Edit"** → **"Add environment variable"**
   
2. Add variable:
   - Key: `FIREBASE_SERVICE_ACCOUNT`
   - Value: **Paste entire content of your downloaded JSON file**
   
3. Click **"Save"**

### Step 5: Create API Gateway (5 minutes)

1. Go to https://console.aws.amazon.com/apigateway/
2. Click **"Create API"**
3. Choose **"HTTP API"** → **"Build"**
4. Settings:
   - API name: `dr-copilot-notifications-api`
   - Integration: **Lambda**
   - Lambda function: Select `dr-copilot-notifications`
   - Method: **POST**
   - Resource path: `/send-notification`
5. Click **"Next"** → **"Next"** → **"Create"**

### Step 6: Get Your API URL ⭐

After creation, you'll see:
```
https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/send-notification
```

**Copy this URL!** You'll use it in Flutter app.

## 🧪 Test Your Setup

### Test 1: Using AWS Console

1. Go to Lambda function
2. Click **"Test" tab**
3. Click **"Create new event"**
4. Paste this JSON:

```json
{
  "httpMethod": "POST",
  "body": "{\"userId\":\"TEST_USER_ID\",\"title\":\"Test Notification\",\"message\":\"Hello from Lambda!\"}"
}
```

5. Click **"Test"**

### Test 2: Using curl (Replace YOUR_USER_ID)

```bash
curl -X POST https://YOUR-API-URL.execute-api.us-east-1.amazonaws.com/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "YOUR_ACTUAL_USER_ID",
    "title": "Test from curl",
    "message": "This is a test!",
    "type": "system"
  }'
```

### Expected Response ✅

```json
{
  "success": true,
  "messageId": "...",
  "userId": "...",
  "timestamp": "2024-..."
}
```

## 📱 Update Flutter App

Add this to your Flutter app notification creation:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendNotificationToUser({
  required String userId,
  required String title,
  required String message,
  String type = 'system',
}) async {
  // 1. Save to Firestore (for history)
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // 2. Send push via AWS Lambda
  try {
    final response = await http.post(
      Uri.parse('https://YOUR-API-URL.execute-api.us-east-1.amazonaws.com/send-notification'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
      }),
    );
    
    if (response.statusCode == 200) {
      print('✅ Push notification sent!');
    } else {
      print('⚠️ Push failed: ${response.body}');
    }
  } catch (e) {
    print('❌ Error sending push: $e');
  }
}
```

## 💰 Cost

### Free Tier (Forever)
- **1 Million requests/month FREE**
- **400,000 GB-seconds compute FREE**

### Your Expected Cost
- **Under 10,000 notifications/day: $0/month** ✅
- **Under 100,000 notifications/day: ~$2-6/month**

## 🔍 Monitoring

### View Logs

1. Go to **CloudWatch** → **Log groups**
2. Find `/aws/lambda/dr-copilot-notifications`
3. View real-time logs

### Metrics

Go to Lambda function → **Monitor tab** to see:
- Invocations
- Duration
- Errors
- Throttles

## ⚡ Quick Commands Reference

### Update Function Code

```bash
cd notification-backend
# Make changes to index.js
Compress-Archive -Path index.js,node_modules,package.json -DestinationPath function.zip -Force

# Upload via AWS Console → Lambda → Upload .zip
```

### View Logs (AWS CLI)

```bash
aws logs tail /aws/lambda/dr-copilot-notifications --follow
```

### Delete Everything (if needed)

```bash
# Delete API
aws apigatewayv2 delete-api --api-id YOUR_API_ID

# Delete Lambda
aws lambda delete-function --function-name dr-copilot-notifications
```

## 🐛 Common Issues

### "Firebase initialization failed"
→ Check environment variable is set correctly

### "User not found"
→ Verify userId exists in Firestore

### "No FCM token found"
→ User needs to sign in to app first

### Function times out
→ Configuration → General → Timeout → Set to 30 seconds

## ✅ Checklist

- [ ] AWS Lambda function created
- [ ] Code uploaded (function.zip)
- [ ] Environment variable set (FIREBASE_SERVICE_ACCOUNT)
- [ ] API Gateway created
- [ ] API URL copied
- [ ] Tested with curl
- [ ] Updated Flutter app
- [ ] Tested end-to-end

## 🎉 Success!

Your notification backend is now live on AWS!

**Next:** Test by creating a notification in Firestore and see it appear as push on your phone!

---

**Need help?** Check `README.md` for detailed documentation.
