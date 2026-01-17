# 🐛 Debug Notification Sender

## Overview
A debug-only page for testing push notifications to users in the Dr. Copilot app.

## Access
**⚠️ Only available in DEBUG mode!**

### How to Access:
1. Run the app in **debug mode**: `flutter run`
2. Navigate to **Notifications** page
3. Look for the **📤 Send icon** button in the app bar (next to the bug icon)
4. Tap it to open the Debug Notification Sender

## Features

### 🎯 Send to Single User
- Enter a specific user ID
- Choose notification type
- Write title and message
- Click "Send to User"

### 📢 Send to All Users (Broadcast)
- Same form as single user
- Click "Send to All Users"
- Confirms before sending
- Sends notification to every user in the database

### 🎨 Notification Types
1. **Appointment** (📅 Purple) - Calendar/appointment reminders
2. **Message** (💬 Indigo) - Chat/message notifications
3. **Reminder** (⏰ Teal) - General reminders
4. **System** (ℹ️ Blue) - System notifications
5. **Payment** (💳 Green) - Payment related
6. **Report** (📊 Orange) - Reports/results
7. **Alert** (⚠️ Red) - Important alerts

### ⚡ Quick Templates
Pre-filled notification templates for common scenarios:
- **Appointment Reminder** - Upcoming doctor appointment
- **Medication Reminder** - Time to take medicine
- **Test Results Ready** - Lab results available
- **New Message** - Doctor message notification

### 📋 Recent Users
The User ID field has a dropdown showing recent users who received notifications - makes it easy to test with existing users.

## Usage Examples

### Example 1: Test Appointment Notification
1. Open Debug Notification Sender
2. Tap "Quick Templates" → "Appointment Reminder"
3. Modify the user ID if needed
4. Click "Send to User"
5. Check the Notifications page to see it appear instantly

### Example 2: Broadcast to All Users
1. Select notification type (e.g., "System")
2. Enter title: "System Maintenance"
3. Enter message: "The app will undergo maintenance tonight at 10 PM"
4. Click "Send to All Users"
5. Confirm the dialog
6. Success! All users will receive it

## Testing Real-Time Updates

### Test Flow:
1. **Open two instances** of the app (or use emulator + real device)
2. **Sign in** with different accounts on each
3. **Open Notifications page** on both
4. **Use Debug Sender** on one device to send to the other user
5. **Watch the notification appear instantly** ✨

## Integration with Firebase

The debug sender writes directly to Firestore:
```
Collection: notifications
Fields:
  - userId: string
  - title: string
  - message: string
  - type: enum
  - isRead: boolean
  - createdAt: timestamp
```

## Security

- ✅ **Only accessible in DEBUG mode** (`kDebugMode`)
- ✅ Button hidden in **RELEASE builds**
- ✅ No authentication required (debug tool)
- ⚠️ **Never deploy with debug features enabled**

## Tips

1. **Quick User ID**: Use Firebase Console to find user IDs, or check the dropdown for recent users
2. **Real-time Testing**: Keep the Notifications page open while sending to see instant updates
3. **Type Testing**: Try all 7 notification types to see different icons/colors
4. **Batch Testing**: Use "Send to All Users" to test how the app handles multiple notifications

## Troubleshooting

### Notification not appearing?
- Check the user is signed in
- Verify user ID is correct
- Check Firebase Console to confirm it was written
- Check for errors in debug console

### "Send to All Users" not working?
- Ensure users collection exists in Firestore
- Check Firestore rules allow reading users
- Verify network connection

## Production Note

**This feature is automatically removed in production builds.** The buttons are wrapped with `if (kDebugMode)` checks and won't appear in release mode.

---

Happy Testing! 🎉
