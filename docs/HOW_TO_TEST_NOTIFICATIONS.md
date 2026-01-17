# 🧪 How to Test Notifications

## Method 1: Manual Test via Firebase Console (Easiest - 2 minutes)

### Step 1: Get Your User ID

**Option A: From Firebase Console**
1. Go to Firebase Authentication:
   ```
   https://console.firebase.google.com/project/drcopilot-bfc9e/authentication/users
   ```
2. Find your signed-in user
3. Copy the **User UID** (looks like: `xYz123AbC...`)

**Option B: From App (Recommended)**
1. Add this button temporarily to your home page or profile:
   ```dart
   ElevatedButton(
     onPressed: () {
       final userId = FirebaseAuth.instance.currentUser?.uid;
       print('MY USER ID: $userId');
       // Or show in a dialog/snackbar
     },
     child: Text('Copy User ID'),
   )
   ```
2. Tap it and copy the ID from console/dialog

---

### Step 2: Create Test Notification in Firestore

1. **Go to Firestore Console:**
   ```
   https://console.firebase.google.com/project/drcopilot-bfc9e/firestore/data
   ```

2. **Click "Start collection"** (if `notifications` doesn't exist yet)
   - Collection ID: `notifications`
   - Click **Next**

3. **Create a document:**
   - Document ID: (leave auto-ID) or use `test_notification_001`

4. **Add fields:**

   | Field | Type | Value |
   |-------|------|-------|
   | `userId` | string | YOUR_USER_ID_HERE (paste from Step 1) |
   | `title` | string | `🎉 Test Notification` |
   | `message` | string | `Hello! This is a test notification to verify the system works.` |
   | `type` | string | `system` |
   | `isRead` | boolean | `false` |
   | `createdAt` | timestamp | Click ⏰ icon → **Use server timestamp** |

5. **Click "Save"**

---

### Step 3: Check the App

1. **Open your app** (or refresh if already open)
2. **Navigate to Notifications tab**
3. **Should see your notification! 🎉**

---

## Method 2: Test with AWS Backend (Production Way)

Since you have AWS backend setup in `notification-backend/`:

### Step 1: Create Test API Endpoint

Create: `notification-backend/test-notification.js`

```javascript
const AWS = require('aws-sdk');
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(require('./serviceAccountKey.json')),
  });
}

const db = admin.firestore();

exports.handler = async (event) => {
  try {
    const { userId, title, message } = JSON.parse(event.body);
    
    // Create notification in Firestore
    const notification = {
      userId: userId,
      title: title || 'Test Notification',
      message: message || 'This is a test notification from AWS Lambda',
      type: 'system',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    const docRef = await db.collection('notifications').add(notification);
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        success: true,
        notificationId: docRef.id,
        message: 'Notification created successfully',
      }),
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
```

### Step 2: Deploy Lambda Function

```bash
cd notification-backend
npm install
# Deploy with your AWS CLI or SAM
```

### Step 3: Test via API

```bash
curl -X POST https://your-api-gateway-url/test-notification \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "YOUR_USER_ID",
    "title": "Test from API",
    "message": "This notification was created via AWS Lambda"
  }'
```

---

## Method 3: Automated Test in Flutter (Best for Development)

Add a test button to your notifications page:

```dart
// In notifications_page.dart, add this floating action button:

floatingActionButton: FloatingActionButton.extended(
  onPressed: () => _createTestNotification(context),
  icon: Icon(Icons.bug_report),
  label: Text('Test Notification'),
),

// Add this method:
Future<void> _createTestNotification(BuildContext context) async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not signed in')),
      );
      return;
    }

    // Create test notification
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': '🧪 Test Notification',
      'message': 'Created at ${DateTime.now().toString()}',
      'type': 'system',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Test notification created!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

Then just tap the button! 🚀

---

## Method 4: Simulate Real Notification Scenarios

### Appointment Reminder
```json
{
  "userId": "YOUR_USER_ID",
  "title": "Appointment Reminder",
  "message": "You have an appointment with Dr. Smith tomorrow at 2:00 PM",
  "type": "appointment",
  "isRead": false,
  "createdAt": [server timestamp],
  "data": {
    "appointmentId": "appt_123",
    "doctorName": "Dr. Smith",
    "appointmentTime": "2024-11-19T14:00:00Z"
  }
}
```

### Prescription Ready
```json
{
  "userId": "YOUR_USER_ID",
  "title": "Prescription Ready",
  "message": "Your prescription is ready for pickup at Pharmacy XYZ",
  "type": "prescription",
  "isRead": false,
  "createdAt": [server timestamp],
  "data": {
    "prescriptionId": "rx_456",
    "pharmacyName": "Pharmacy XYZ"
  }
}
```

### System Alert
```json
{
  "userId": "YOUR_USER_ID",
  "title": "System Update",
  "message": "New features are now available! Check them out.",
  "type": "system",
  "isRead": false,
  "createdAt": [server timestamp]
}
```

---

## ✅ What to Test

After creating notifications, verify:

1. **Display:**
   - ✅ Notifications appear in the list
   - ✅ Title and message are correct
   - ✅ Unread count badge updates
   - ✅ Icons display correctly based on type

2. **Interactions:**
   - ✅ Tap notification → marks as read
   - ✅ Swipe to delete → notification removed
   - ✅ "Mark all as read" button works
   - ✅ "Clear all" button works

3. **Real-time Updates:**
   - ✅ New notifications appear instantly
   - ✅ Unread count updates in real-time
   - ✅ Changes sync across tabs/windows

4. **Edge Cases:**
   - ✅ Empty state shows "No notifications"
   - ✅ Error handling works (try invalid data)
   - ✅ Loading state displays correctly

---

## 🐛 Troubleshooting

### Notification doesn't appear
- ✅ Check `userId` matches your signed-in user
- ✅ Verify Firestore rules are deployed
- ✅ Check browser console for errors
- ✅ Make sure indexes are built

### Permission denied error
- ✅ Deploy Firestore rules
- ✅ Make sure you're signed in
- ✅ Check userId is correct

### Index required error
- ✅ Click the link in console to create index
- ✅ Wait 2-5 minutes for index to build

---

## 📊 Testing Checklist

- [ ] Firestore rules deployed
- [ ] Firestore indexes created
- [ ] Get your User ID
- [ ] Create test notification via console
- [ ] Verify notification appears
- [ ] Test mark as read
- [ ] Test delete
- [ ] Test mark all as read
- [ ] Test real-time updates
- [ ] Test with multiple notifications

---

## 🚀 Quick Test Script

For rapid testing, run this in browser console (when app is open):

```javascript
// Get Firebase instance
const db = firebase.firestore();
const userId = firebase.auth().currentUser.uid;

// Create test notification
db.collection('notifications').add({
  userId: userId,
  title: '🚀 Quick Test',
  message: `Created at ${new Date().toLocaleTimeString()}`,
  type: 'system',
  isRead: false,
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
}).then(() => console.log('✅ Test notification created!'));
```

---

## 📝 Notes

- **Use Method 1** for quick manual testing
- **Use Method 3** for development/debugging  
- **Use Method 2** for production testing
- Always test with **your actual User ID**
- Test notifications appear **instantly** due to Firestore real-time listeners

---

**Ready to test? Start with Method 1!** 🎉
