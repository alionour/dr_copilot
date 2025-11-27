# Dr. Copilot Backend - Flutter Integration Guide

## API Endpoint

**Base URL**: `https://hg4orotvf0.execute-api.us-east-1.amazonaws.com`

---

## 1. Health Check Endpoint

### Endpoint
```
GET /
```

### Purpose
Check if the backend is running and Firebase is initialized.

### Flutter Example
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> checkBackendHealth() async {
  try {
    final response = await http.get(
      Uri.parse('https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Backend status: ${data['message']}');
      print('Firebase initialized: ${data['firebaseInitialized']}');
      return data['firebaseInitialized'] == true;
    }
    return false;
  } catch (e) {
    print('Health check failed: $e');
    return false;
  }
}
```

### Response
```json
{
  "message": "Dr. Copilot Backend is running!",
  "timestamp": "2025-11-21T07:56:01.529Z",
  "firebaseInitialized": true
}
```

---

## 2. Send Invitation Email

### Endpoint
```
POST /invitations
```

### Purpose
Send an invitation email to a new user (doctor, nurse, staff).

### Request Body
```json
{
  "recipientEmail": "user@example.com",
  "recipientName": "John Doe",
  "clinicName": "Sunshine Pediatrics",
  "role": "Doctor"
}
```

### Flutter Example
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> sendInvitation({
  required String recipientEmail,
  required String recipientName,
  required String clinicName,
  required String role,
}) async {
  const baseUrl = 'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com';
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/invitations'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'recipientEmail': recipientEmail,
        'recipientName': recipientName,
        'clinicName': clinicName,
        'role': role,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Invitation sent: ${data['messageId']}');
      return data['success'] == true;
    } else {
      final error = json.decode(response.body);
      print('Error: ${error['message']}');
      return false;
    }
  } catch (e) {
    print('Failed to send invitation: $e');
    return false;
  }
}

// Usage
await sendInvitation(
  recipientEmail: 'doctor@example.com',
  recipientName: 'Dr. Smith',
  clinicName: 'Main Street Clinic',
  role: 'Doctor',
);
```

### Success Response
```json
{
  "success": true,
  "message": "Invitation email sent successfully.",
  "messageId": "0100019aa575c403-f832bdc4-f4ba-44d2-a887-7e8c30ad0db9-000000"
}
```

### Error Response
```json
{
  "error": "Internal Server Error",
  "message": "Email address is not verified..."
}
```

---

## 3. Send Push Notification

### Endpoint
```
POST /notifications
```

### Purpose
Send a push notification to a user via Firebase Cloud Messaging.

### Request Body
```json
{
  "userId": "firebase-user-id",
  "title": "New Appointment",
  "message": "You have a new appointment at 2:00 PM."
}
```

### Flutter Example
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> sendNotification({
  required String userId,
  required String title,
  required String message,
}) async {
  const baseUrl = 'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com';
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'title': title,
        'message': message,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Notification sent: ${data['messageId']}');
      return data['success'] == true;
    } else {
      final error = json.decode(response.body);
      print('Error: ${error['message']}');
      return false;
    }
  } catch (e) {
    print('Failed to send notification: $e');
    return false;
  }
}

// Usage
await sendNotification(
  userId: 'user123',
  title: 'Appointment Reminder',
  message: 'Your appointment is in 1 hour',
);
```

---

## 4. Complete Service Class

Here's a complete service class you can use in your Flutter app:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class BackendService {
  static const String baseUrl = 
    'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com';
  
  // Health check
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['firebaseInitialized'] == true;
      }
      return false;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
  
  // Send invitation
  static Future<Map<String, dynamic>> sendInvitation({
    required String recipientEmail,
    required String recipientName,
    required String clinicName,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invitations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'recipientEmail': recipientEmail,
          'recipientName': recipientName,
          'clinicName': clinicName,
          'role': role,
        }),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'messageId': data['messageId'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to send invitation: $e',
      };
    }
  }
  
  // Send notification
  static Future<Map<String, dynamic>> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'title': title,
          'message': message,
        }),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'messageId': data['messageId'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to send notification: $e',
      };
    }
  }
}
```

### Usage in Your App

```dart
// In your invitation page
final result = await BackendService.sendInvitation(
  recipientEmail: emailController.text,
  recipientName: nameController.text,
  clinicName: clinicNameController.text,
  role: selectedRole,
);

if (result['success']) {
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Invitation sent successfully!')),
  );
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${result['error']}')),
  );
}
```

---

## 5. Add HTTP Package

Don't forget to add the `http` package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # Add this line
```

Then run:
```bash
flutter pub get
```

---

## 6. Important Notes

### SES Sandbox Mode (Current)
- Can only send emails TO verified addresses
- Verified: `nourrehabcenter@gmail.com`, `alionour22@gmail.com`
- For testing, send invitations to these emails

### After SES Production Approval
- Can send to ANY email address
- No code changes needed
- Just works automatically

### Error Handling
Always handle errors gracefully:
```dart
try {
  final result = await BackendService.sendInvitation(...);
  if (!result['success']) {
    // Handle error
    print('Error: ${result['error']}');
  }
} catch (e) {
  // Handle exception
  print('Exception: $e');
}
```

---

## 7. Environment Configuration

Consider using environment variables for the API URL:

```dart
class Config {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com',
  );
}

// Use in service
static const String baseUrl = Config.apiBaseUrl;
```

---

## Summary

✅ **Backend API**: Ready to use  
✅ **Health Check**: `/`  
✅ **Invitations**: `POST /invitations`  
✅ **Notifications**: `POST /notifications`  
✅ **Cost**: $0 (AWS Free Tier)  
✅ **Performance**: Fast (Lambda)  

Your backend is ready for integration! 🚀
