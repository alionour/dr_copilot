# 🚀 Deploy Lambda Function - 10 Minutes

## ✅ AWS CLI Configured Successfully!
- Account ID: `426728254000`
- Region: `us-east-1`
- IAM Role: `dr-copilot-lambda-role` ✅ Created

## 📦 Files Ready
- ✅ `function.zip` (11.4 MB) - Ready to upload
- ✅ IAM role configured
- ✅ AWS credentials set

---

## 🎯 Deploy via AWS Console (Recommended - 10 minutes)

The CLI upload is timing out due to file size. AWS Console is more reliable.

### Step 1: Create Lambda Function (3 minutes)

1. **Open AWS Lambda Console:**
   https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions

2. **Click "Create function"**

3. **Configure:**
   - Choose: **"Author from scratch"**
   - Function name: `dr-copilot-notifications`
   - Runtime: **Node.js 18.x**
   - Architecture: **x86_64**
   - Permissions: **Use an existing role**
   - Existing role: **dr-copilot-lambda-role** ✅ (Already created!)

4. **Click "Create function"**

### Step 2: Upload Code (3 minutes)

1. **In the function page:**
   - Go to **"Code"** tab
   - Click **"Upload from"** → **".zip file"**

2. **Select file:**
   ```
   F:\Ali\Projects\alionour33\dr_copilot\notification-backend\function.zip
   ```

3. **Click "Save"**
   - Wait for upload to complete (~30 seconds)

4. **Verify:**
   - You should see `index.js` and `node_modules/` in the code editor

### Step 3: Configure (2 minutes)

1. **Go to "Configuration" tab** → **"General configuration"**
2. **Click "Edit"**
3. **Set:**
   - Timeout: **30 seconds**
   - Memory: **256 MB** (already set)
4. **Click "Save"**

### Step 4: Add Firebase Credentials (5 minutes)

**IMPORTANT:** You need your Firebase Service Account Key!

#### Get Firebase Key:
1. Go to https://console.firebase.google.com/
2. Select project: **drcopilot-bfc9e**
3. Click ⚙️ → **Project Settings**
4. Go to **"Service Accounts"** tab
5. Click **"Generate New Private Key"**
6. **Download the JSON file**
7. **Open it with notepad** and copy ALL content

#### Add to Lambda:
1. In Lambda function, go to **"Configuration"** → **"Environment variables"**
2. Click **"Edit"** → **"Add environment variable"**
3. Add:
   - **Key:** `FIREBASE_SERVICE_ACCOUNT`
   - **Value:** Paste the entire JSON content you copied
4. Click **"Save"**

### Step 5: Create API Gateway (3 minutes)

1. **Open API Gateway Console:**
   https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis

2. **Click "Create API"**

3. **Choose "HTTP API"** → **"Build"**

4. **Configure:**
   - **Add integration:**
     - Type: **Lambda**
     - AWS Region: **us-east-1**
     - Lambda function: **dr-copilot-notifications**
   
5. **API name:** `dr-copilot-notifications-api`

6. **Click "Next"**

7. **Configure routes:**
   - Method: **POST**
   - Resource path: **/send-notification**

8. **Click "Next"** → **"Next"** → **"Create"**

### Step 6: Get Your API URL ⭐

After creation, you'll see:
```
Invoke URL: https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com
```

**Your full endpoint will be:**
```
https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/send-notification
```

**📋 COPY THIS URL!** You'll use it in Flutter app.

---

## 🧪 Test Your Lambda Function

### Test in AWS Console

1. Go to Lambda function page
2. Click **"Test"** tab
3. Click **"Create new event"**
4. **Event name:** `test-notification`
5. **Paste this JSON:**

```json
{
  "httpMethod": "POST",
  "body": "{\"userId\":\"TEST_USER\",\"title\":\"Test Notification\",\"message\":\"Hello from Lambda!\"}"
}
```

6. Click **"Test"**

### Expected Result:

**If Firebase credentials NOT set yet:**
```json
{
  "statusCode": 500,
  "body": "{\"error\":\"Firebase initialization failed\"}"
}
```
→ Go back and add Firebase credentials (Step 4)

**If Firebase credentials set:**
```json
{
  "statusCode": 404,
  "body": "{\"error\":\"User not found\",\"userId\":\"TEST_USER\"}"
}
```
→ This is GOOD! Lambda is working, just no test user in Firestore yet.

---

## 🎉 Success Checklist

- [ ] Lambda function created
- [ ] Code uploaded (function.zip)
- [ ] Timeout set to 30 seconds
- [ ] Firebase credentials added
- [ ] API Gateway created
- [ ] API URL copied
- [ ] Test passed

---

## 📱 Next: Update Flutter App

Once you have your API URL, add it to your Flutter app:

```dart
// lib/src/core/config/api_config.dart (create this file)
class ApiConfig {
  static const String notificationApiUrl = 
    'https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/send-notification';
}

// Usage in notification service:
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendPushNotification({
  required String userId,
  required String title,
  required String message,
  String type = 'system',
}) async {
  final response = await http.post(
    Uri.parse(ApiConfig.notificationApiUrl),
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
    print('⚠️ Failed: ${response.body}');
  }
}
```

---

## 💰 Your Cost

- **IAM Role:** Free
- **Lambda function:** Free (up to 1M requests/month)
- **API Gateway:** Free (up to 1M requests/month)
- **Total:** **$0/month** for most apps! 🎉

---

## 🐛 Troubleshooting

### Function times out during upload
→ Use AWS Console instead of CLI (this guide)

### Firebase initialization failed
→ Check environment variable is set correctly
→ Verify JSON is valid (no extra quotes, complete file)

### User not found error
→ This is normal for test! Means Lambda is working
→ Test with real user ID from Firestore

### API Gateway not working
→ Check Lambda has permissions for API Gateway
→ Verify route is `/send-notification` with POST method

---

## 📞 Need Help?

1. Check CloudWatch Logs:
   - CloudWatch → Log groups → `/aws/lambda/dr-copilot-notifications`

2. Verify IAM role permissions

3. Test Lambda function directly (without API Gateway) first

---

## ✅ You're Almost Done!

Just follow the steps above - 10 minutes to go live! 🚀
