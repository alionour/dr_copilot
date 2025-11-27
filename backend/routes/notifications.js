const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();

// POST /notifications - Send a push notification
router.post('/', async (req, res, next) => {
    // --- Prerequisite Check ---
    if (admin.apps.length === 0) {
        // This error occurs if the FIREBASE_SERVICE_ACCOUNT env var is missing or invalid.
        return next(new Error('Firebase Admin SDK has not been initialized. Check server configuration.'));
    }

    // --- Request Body Validation ---
    const { userId, title, message, type, actionUrl, notificationId } = req.body;

    if (!userId || !title || !message) {
        const missingFields = [!userId && "userId", !title && "title", !message && "message"].filter(Boolean).join(", ");
        return res.status(400).json({
            error: `Missing required fields: ${missingFields}`
        });
    }

    try {
        console.log(`Processing notification for user: ${userId}`);

        // --- Get User's FCM Token ---
        const userDoc = await admin.firestore().collection('users').doc(userId).get();

        if (!userDoc.exists) {
            console.log(`User not found: ${userId}`);
            return res.status(404).json({
                error: 'User not found',
                userId: userId
            });
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`No FCM token found for user: ${userId}`);
            return res.status(404).json({
                error: 'No FCM token found for user',
                userId: userId,
                hint: 'User needs to sign in to the app to register their FCM token.'
            });
        }

        console.log(`FCM token found for user: ${userId}`);

        // --- Prepare FCM Message Payload ---
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
                headers: { 'apns-priority': '10' },
                payload: {
                    aps: {
                        alert: { title: title, body: message },
                        sound: 'default',
                        badge: 1,
                        'content-available': 1
                    }
                }
            }
        };

        // --- Send FCM Notification ---
        const messageId = await admin.messaging().send(fcmMessage);
        console.log(`Notification sent successfully. Message ID: ${messageId}`);

        res.status(200).json({
            success: true,
            messageId: messageId,
            userId: userId,
            details: {
                title: title,
                type: type || 'system'
            }
        });

    } catch (fcmError) {
        console.error('FCM Error:', fcmError);

        // Handle specific FCM errors for invalid tokens
        if (fcmError.code === 'messaging/invalid-registration-token' ||
            fcmError.code === 'messaging/registration-token-not-registered') {

            // Asynchronously remove the invalid token from the user's document
            admin.firestore().collection('users').doc(userId).update({
                fcmToken: admin.firestore.FieldValue.delete(),
                fcmTokenInvalidatedAt: admin.firestore.FieldValue.serverTimestamp()
            }).catch(err => console.error(`Failed to remove invalid token for user ${userId}:`, err));

            return res.status(410).json({
                error: 'FCM token is invalid or expired.',
                code: fcmError.code,
                message: 'User needs to sign in again to refresh their token.'
            });
        }

        // Pass other errors to the global error handler
        next(fcmError);
    }
});

module.exports = router;