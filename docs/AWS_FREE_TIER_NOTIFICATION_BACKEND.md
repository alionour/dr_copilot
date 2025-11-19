# AWS Free Tier for Notification Backend

## YES! AWS Has EXCELLENT Free Tier Options 🎉

### AWS Free Tier Overview

AWS offers **12 months free** + **Always free** services that are perfect for notification backend!

---

## 🥇 Best AWS Options for Notification Backend

### Option 1: **AWS Lambda + API Gateway** (BEST - Always Free)

#### Free Tier:
- ✅ **1 Million Lambda requests/month FREE (Forever)**
- ✅ **400,000 GB-seconds compute/month FREE**
- ✅ **1 Million API Gateway requests FREE (12 months)**
- ✅ **After 12 months: $3.50 per million requests**
- ✅ **No server management**
- ✅ **Auto-scaling**
- ✅ **Pay per use (very cheap after free tier)**

#### Perfect For:
- Production apps
- Variable traffic
- Cost optimization

#### Cost After Free Tier:
- ~$0.20/month for 5,000 notifications/day
- ~$2-3/month for 50,000 notifications/day

#### Reliability: ⭐⭐⭐⭐⭐ (Enterprise-grade)

---

### Option 2: **AWS Lightsail** (Cheapest VPS)

#### Pricing:
- ✅ **First 3 months FREE** (750 hours/month)
- ✅ **After: $3.50/month** (smallest instance)
- ✅ **Always on**
- ✅ **1TB bandwidth included**
- ✅ **Static IP included**
- ✅ **Easy to manage**

#### Perfect For:
- Simple dedicated server
- Predictable costs
- Traditional hosting

#### Reliability: ⭐⭐⭐⭐⭐

---

### Option 3: **AWS EC2 Free Tier** (12 Months Free)

#### Free Tier:
- ✅ **750 hours/month FREE (12 months)**
- ✅ **t2.micro instance** (1GB RAM)
- ✅ **30GB storage**
- ✅ **15GB bandwidth/month**
- ✅ **Full Linux server**

#### Perfect For:
- First year free
- Full control

#### After 12 Months:
- ~$8-10/month

#### Reliability: ⭐⭐⭐⭐⭐

---

## Detailed Comparison

### AWS Lambda vs Fly.io vs Koyeb

| Feature | AWS Lambda | Fly.io | Koyeb |
|---------|-----------|---------|-------|
| **Free Tier** | 1M requests/month | 3 VMs always on | 2 services always on |
| **Cost Forever?** | ⚠️ After 1M req | ✅ Yes | ✅ Yes |
| **Always On** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Cold Start** | ~100-500ms | No | No |
| **Setup Difficulty** | Medium | Easy | Very Easy |
| **Scalability** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Cost at 10K/day** | ~$0.50/mo | $0 | $0 |
| **Cost at 100K/day** | ~$5/mo | May exceed | May exceed |

---

## 🎯 AWS Lambda Implementation (Recommended)

### Why Lambda is PERFECT for Notifications:

1. ✅ **Pay per use** (only when notifications sent)
2. ✅ **1 Million free requests forever**
3. ✅ **Auto-scales** (handle any traffic)
4. ✅ **No server management**
5. ✅ **Enterprise reliability**
6. ✅ **Cheap even after free tier**

### Architecture:

```
Flutter App
    ↓
API Gateway (HTTPS endpoint)
    ↓
AWS Lambda Function
    ↓
Firebase Admin SDK → Send FCM Push
```

---

## Complete AWS Lambda Setup

### Method 1: AWS Lambda with API Gateway (Serverless)

#### File Structure:
```
notification-backend/
├── index.js                 # Lambda handler
├── package.json            # Dependencies
├── serviceAccountKey.json  # Firebase credentials
└── README.md              # Deployment guide
```

#### 1. **index.js** (Lambda Function)
```javascript
const admin = require('firebase-admin');

// Initialize Firebase Admin (only once)
let firebaseApp;
if (!admin.apps.length) {
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

exports.handler = async (event) => {
  // CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json'
  };

  // Handle preflight
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  try {
    // Parse request body
    const body = JSON.parse(event.body);
    const { userId, title, message, type, actionUrl, notificationId } = body;

    // Validate required fields
    if (!userId || !title || !message) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Missing required fields' })
      };
    }

    // Get user's FCM token from Firestore
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ error: 'User not found' })
      };
    }

    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) {
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ error: 'No FCM token found for user' })
      };
    }

    // Prepare FCM message
    const fcmMessage = {
      token: fcmToken,
      notification: {
        title: title,
        body: message
      },
      data: {
        type: type || 'system',
        actionUrl: actionUrl || '/notifications',
        notificationId: notificationId || '',
        userId: userId
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'high_importance_channel'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    // Send FCM notification
    const response = await admin.messaging().send(fcmMessage);

    console.log('Notification sent successfully:', response);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        messageId: response,
        timestamp: new Date().toISOString()
      })
    };

  } catch (error) {
    console.error('Error sending notification:', error);

    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: 'Internal server error',
        message: error.message
      })
    };
  }
};
```

#### 2. **package.json**
```json
{
  "name": "notification-backend",
  "version": "1.0.0",
  "description": "AWS Lambda notification backend for dr_copilot",
  "main": "index.js",
  "scripts": {
    "deploy": "zip -r function.zip index.js node_modules package.json"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0"
  }
}
```

---

## Deployment Steps (AWS Lambda)

### Using AWS Console (Easiest):

#### Step 1: Create Lambda Function (5 minutes)

```bash
# 1. Go to AWS Console → Lambda
# 2. Click "Create function"
# 3. Choose "Author from scratch"
# 4. Function name: dr-copilot-notifications
# 5. Runtime: Node.js 18.x
# 6. Click "Create function"
```

#### Step 2: Upload Code (3 minutes)

```bash
# On your computer:
cd notification-backend
npm install
zip -r function.zip index.js node_modules package.json

# In AWS Console:
# 1. Upload function.zip
# 2. Click "Upload from" → ".zip file"
# 3. Upload function.zip
```

#### Step 3: Add Firebase Credentials (2 minutes)

```bash
# In AWS Lambda Console:
# 1. Go to "Configuration" → "Environment variables"
# 2. Add variable:
#    Key: FIREBASE_SERVICE_ACCOUNT
#    Value: [Paste your serviceAccountKey.json content]
```

#### Step 4: Create API Gateway (5 minutes)

```bash
# 1. Go to API Gateway in AWS Console
# 2. Click "Create API"
# 3. Choose "HTTP API"
# 4. Integration: Lambda
# 5. Select your function
# 6. Route: POST /send-notification
# 7. Click "Create"

# You'll get URL like:
# https://abc123.execute-api.us-east-1.amazonaws.com/send-notification
```

#### Step 5: Test (2 minutes)

```bash
# Use Postman or curl:
curl -X POST https://YOUR-API-URL/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user-id",
    "title": "Test Notification",
    "message": "This is a test"
  }'
```

**Total Time: 17 minutes**

---

## Using AWS CLI (Advanced - Faster)

```bash
# Install AWS CLI
# Windows: https://aws.amazon.com/cli/

# Configure
aws configure

# Create function
aws lambda create-function \
  --function-name dr-copilot-notifications \
  --runtime nodejs18.x \
  --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-execution-role \
  --handler index.handler \
  --zip-file fileb://function.zip

# Create API Gateway
aws apigatewayv2 create-api \
  --name dr-copilot-notifications-api \
  --protocol-type HTTP \
  --target arn:aws:lambda:us-east-1:YOUR_ACCOUNT:function:dr-copilot-notifications
```

---

## Cost Comparison: Real Numbers

### Scenario: 5,000 notifications/day (150,000/month)

| Service | Month 1 | Month 12 | Month 24 | Best For |
|---------|---------|----------|----------|----------|
| **AWS Lambda** | $0 | $0 | $0.60/mo | Production ⭐ |
| **Fly.io** | $0 | $0 | $0 | Medium traffic |
| **Koyeb** | $0 | $0 | $0 | Medium traffic |
| **Lightsail** | $0 | $0 | $3.50/mo | Simple VPS |
| **EC2** | $0 | $10/mo | $10/mo | Full control |
| **Cloud Functions** | $60/yr | $60/yr | $60/yr | Needs billing ❌ |

### Scenario: 50,000 notifications/day (1.5M/month)

| Service | Cost/Month | Notes |
|---------|------------|-------|
| **AWS Lambda** | ~$3-5 | Still very cheap |
| **Fly.io** | ~$0-5 | May hit limits |
| **Koyeb** | ~$0-5 | May hit limits |
| **Lightsail** | $3.50 | Fixed cost |
| **EC2** | $10 | Overkill |

---

## Final Recommendation for dr_copilot

### TOP 3 OPTIONS (All Excellent):

### 🥇 **1. AWS Lambda** (Best for Long-term)

**Pros:**
- ✅ 1M requests FREE forever
- ✅ Cheapest at scale
- ✅ Enterprise reliability
- ✅ Auto-scales infinitely
- ✅ No server management

**Cons:**
- ⚠️ Slightly more complex setup (17 minutes)
- ⚠️ 100-500ms cold start (rare)

**Best if:** You want enterprise-grade, long-term solution

---

### 🥈 **2. Fly.io** (Best for Simplicity)

**Pros:**
- ✅ 100% free forever (within limits)
- ✅ Always on (no cold starts)
- ✅ Easiest setup (10 minutes)
- ✅ Simple pricing

**Cons:**
- ⚠️ Limited to 3 VMs
- ⚠️ May hit limits at very high traffic

**Best if:** You want simple, quick setup

---

### 🥉 **3. Koyeb** (Best for Beginners)

**Pros:**
- ✅ Simplest setup (5 minutes)
- ✅ Always on
- ✅ More RAM than Fly.io
- ✅ Auto-deploy from GitHub

**Cons:**
- ⚠️ Newer service
- ⚠️ Less proven at scale

**Best if:** You want easiest deployment

---

## My Recommendation for You

### Use **AWS Lambda** if:
- ✅ You plan long-term production use
- ✅ You want cheapest at scale
- ✅ You're okay with 17-minute setup
- ✅ You want AWS reliability

### Use **Fly.io** if:
- ✅ You want fastest setup
- ✅ You want always-on (no cold starts)
- ✅ You prefer simplicity
- ✅ Your traffic is under 10K/day

### Use **Koyeb** if:
- ✅ You want GitHub auto-deploy
- ✅ You want simplest possible setup
- ✅ You're building MVP/testing

---

## What I'll Create for You

I can create complete backend code for **any** of these:

### Option A: AWS Lambda Package
- ✅ Lambda function code
- ✅ Deployment scripts
- ✅ AWS CLI commands
- ✅ Step-by-step guide

### Option B: Fly.io Package
- ✅ Node.js server
- ✅ Dockerfile
- ✅ fly.toml config
- ✅ Deployment guide

### Option C: Koyeb Package
- ✅ Node.js server
- ✅ GitHub Actions
- ✅ One-click deploy

---

## Quick Decision Guide

**Answer these questions:**

1. **How many notifications per day?**
   - < 5,000 → Fly.io or Koyeb (free forever)
   - > 5,000 → AWS Lambda (cheapest)

2. **Setup time preference?**
   - 5 minutes → Koyeb
   - 10 minutes → Fly.io
   - 15-20 minutes → AWS Lambda

3. **Technical comfort?**
   - Beginner → Koyeb
   - Intermediate → Fly.io
   - Advanced → AWS Lambda

4. **Long-term plan?**
   - Small app → Fly.io/Koyeb
   - Growing app → AWS Lambda
   - Enterprise → AWS Lambda

---

## Which Do You Want?

**Tell me your choice and I'll create the complete implementation:**

1. **AWS Lambda** (best for production, cheapest at scale)
2. **Fly.io** (best for simplicity, always-on)
3. **Koyeb** (easiest setup)

Or say **"compare all 3"** and I'll create all three so you can try them!
