const admin = require('firebase-admin');

// Initialize Firebase Admin (only once)
let firebaseApp;

/**
 * AWS Lambda handler for sending push notifications via FCM
 * 
 * @param {Object} event - API Gateway Lambda Proxy Input Format
 * @param {Object} context - Lambda Context runtime methods and attributes
 * @returns {Object} - API Gateway Lambda Proxy Output Format
 */
exports.handler = async (event, context) => {
  // CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json'
  };

  // Handle preflight OPTIONS request
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: ''
    };
  }

  // Initialize Firebase Admin on first invocation
  if (!admin.apps.length) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log('Firebase Admin initialized successfully');
    } catch (error) {
      console.error('Error initializing Firebase Admin:', error);
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({ 
          error: 'Firebase initialization failed',
          message: error.message 
        })
      };
    }
  }

  try {
    // Parse request body
    let body;
    try {
      body = JSON.parse(event.body || '{}');
    } catch (parseError) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ 
          error: 'Invalid JSON in request body',
          message: parseError.message 
        })
      };
    }

    const { userId, title, message, type, actionUrl, notificationId } = body;

    // Validate required fields
    if (!userId || !title || !message) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ 
          error: 'Missing required fields',
          required: ['userId', 'title', 'message']
        })
      };
    }

    console.log(`Processing notification for user: ${userId}`);

    // Get user's FCM token from Firestore
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      console.log(`User not found: ${userId}`);
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ 
          error: 'User not found',
          userId: userId 
        })
      };
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token found for user: ${userId}`);
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ 
          error: 'No FCM token found for user',
          userId: userId,
          hint: 'User needs to sign in to the app to register FCM token'
        })
      };
    }

    console.log(`FCM token found for user: ${userId}`);

    // Prepare FCM message payload
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
        userId: userId,
        timestamp: new Date().toISOString()
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'high_importance_channel',
          priority: 'high',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        }
      },
      apns: {
        headers: {
          'apns-priority': '10'
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: message
            },
            sound: 'default',
            badge: 1,
            'content-available': 1
          }
        }
      }
    };

    // Send FCM notification
    let messageId;
    try {
      messageId = await admin.messaging().send(fcmMessage);
      console.log(`Notification sent successfully. Message ID: ${messageId}`);
    } catch (fcmError) {
      console.error('FCM Error:', fcmError);
      
      // Handle specific FCM errors
      if (fcmError.code === 'messaging/invalid-registration-token' ||
          fcmError.code === 'messaging/registration-token-not-registered') {
        // Token is invalid, remove it from user document
        await admin.firestore()
          .collection('users')
          .doc(userId)
          .update({
            fcmToken: admin.firestore.FieldValue.delete(),
            fcmTokenInvalidatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        
        return {
          statusCode: 410,
          headers,
          body: JSON.stringify({
            error: 'FCM token is invalid or expired',
            code: fcmError.code,
            message: 'User needs to sign in again to refresh token'
          })
        };
      }
      
      throw fcmError;
    }

    // Return success response
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        messageId: messageId,
        userId: userId,
        timestamp: new Date().toISOString(),
        details: {
          title: title,
          type: type || 'system'
        }
      })
    };

  } catch (error) {
    console.error('Error sending notification:', error);

    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: 'Internal server error',
        message: error.message,
        code: error.code || 'UNKNOWN_ERROR'
      })
    };
  }
};
