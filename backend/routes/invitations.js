const express = require('express');
const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
const crypto = require('crypto');
const admin = require('firebase-admin');

const router = express.Router();

// Initialize SES client
const sesClient = new SESClient({});

// POST /invitations - Send an invitation email
router.post('/', async (req, res, next) => {
    console.log('--- /invitations route invoked ---');
    console.log('Request Body:', JSON.stringify(req.body, null, 2));

    // --- Environment Variable Checks ---
    const { SES_FROM_EMAIL, APP_URL } = process.env;
    if (!SES_FROM_EMAIL || !APP_URL) {
        const missingVars = [!SES_FROM_EMAIL && "SES_FROM_EMAIL", !APP_URL && "APP_URL"].filter(Boolean).join(", ");
        console.error(`Configuration error: Missing environment variables: ${missingVars}`);
        // This is a server configuration error, so we pass it to the error handler
        return next(new Error(`Server is misconfigured. Missing: ${missingVars}`));
    }
    console.log('Environment variables loaded successfully.');

    // --- Request Body Validation ---
    const { recipientEmail, recipientName, clinicName, clinicId, role } = req.body;

    if (!recipientEmail || !clinicName || !clinicId || !role) {
        const missingFields = [
            !recipientEmail && "recipientEmail",
            !clinicName && "clinicName",
            !clinicId && "clinicId",
            !role && "role"
        ].filter(Boolean).join(", ");
        console.error(`Validation failed. Missing fields: ${missingFields}`);
        return res.status(400).json({
            error: `Missing required fields: ${missingFields}`
        });
    }
    console.log(`Validation successful for recipient: ${recipientEmail}`);

    // --- Generate Invitation Token ---
    const token = crypto.randomBytes(32).toString('hex');
    console.log(`Generated invitation token: ${token}`);

    // --- Store Invitation in Firestore ---
    try {
        const db = admin.firestore();
        await db.collection('invitations').doc(token).set({
            token,
            recipientEmail,
            recipientName: recipientName || '',
            clinicId,
            clinicName,
            role,
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
            acceptedAt: null,
            acceptedBy: null
        });
        console.log(`Invitation stored in Firestore with token: ${token}`);
    } catch (firestoreError) {
        console.error('Error storing invitation in Firestore:', firestoreError);
        return next(new Error('Failed to create invitation'));
    }

    // --- Email Content Creation ---
    const subject = `You're invited to join ${clinicName} on Dr. Copilot`;

    const createHtmlBody = () => `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Dr. Copilot Invitation</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 20px auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px; }
            .header { font-size: 24px; font-weight: bold; text-align: center; color: #4A90E2; }
            .content { margin-top: 20px; }
            .button { display: inline-block; padding: 12px 24px; margin: 20px 0; background-color: #4A90E2; color: #fff; text-decoration: none; border-radius: 5px; font-weight: bold; }
            .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">Dr. Copilot</div>
            <div class="content">
                <h2>You're Invited!</h2>
                <p>Hello ${recipientName || ''},</p>
                <p>You have been invited to join <strong>${clinicName}</strong> on the Dr. Copilot platform with the role of <strong>${role}</strong>.</p>
                <p>Click the button below to accept the invitation and create your account. Please be sure to sign up using this email address (${recipientEmail}).</p>
                <a href="${APP_URL}/accept-invitation?token=${token}" class="button">Accept Invitation & Sign Up</a>
                <p>If you have any questions, please contact your clinic administrator.</p>
                <p>Thank you,<br>The Dr. Copilot Team</p>
            </div>
            <div class="footer">
                If you did not expect this invitation, you can safely ignore this email.
            </div>
        </div>
    </body>
    </html>
    `;

    const htmlBody = createHtmlBody();

    const textBody = `
    Hello ${recipientName || ''},
    
    You have been invited to join ${clinicName} on the Dr. Copilot platform with the role of ${role}.
    
    Please visit the following URL to accept the invitation and create your account. Be sure to sign up using this email address (${recipientEmail}).
    
    Sign-up Link: ${APP_URL}/accept-invitation?token=${token}
    
    Thank you,
    The Dr. Copilot Team
    `;

    // --- SES SendEmailCommand Parameters ---
    const params = {
        Destination: {
            ToAddresses: [recipientEmail],
        },
        Message: {
            Body: {
                Html: {
                    Charset: "UTF-8",
                    Data: htmlBody,
                },
                Text: {
                    Charset: "UTF-8",
                    Data: textBody,
                },
            },
            Subject: {
                Charset: "UTF-8",
                Data: subject,
            },
        },
        Source: SES_FROM_EMAIL,
    };

    console.log('Attempting to send email via SES...');
    console.log('SES Params (excluding body):', JSON.stringify({ ...params, Message: { ...params.Message, Body: "..." } }, null, 2));

    // --- Send Email via SES ---
    try {
        const command = new SendEmailCommand(params);
        const data = await sesClient.send(command);
        console.log(`Email sent successfully to ${recipientEmail}. Message ID: ${data.MessageId}`);
        res.status(200).json({
            success: true,
            message: 'Invitation email sent successfully.',
            messageId: data.MessageId
        });
    } catch (error) {
        console.error('--- SES SEND ERROR ---');
        console.error('Error sending email via SES:', JSON.stringify(error, null, 2));
        console.error('Error Name:', error.name);
        console.error('Error Message:', error.message);
        // Pass the error to the global error handler in index.js
        next(error);
    }
});

// GET /invitations/verify - Verify invitation token
router.get('/verify', async (req, res, next) => {
    console.log('--- /invitations/verify route invoked ---');
    const { token } = req.query;

    if (!token) {
        return res.status(400).json({ valid: false, error: 'Token is required' });
    }

    try {
        const db = admin.firestore();
        const invitationDoc = await db.collection('invitations').doc(token).get();

        if (!invitationDoc.exists) {
            console.log(`Invalid token: ${token}`);
            return res.status(404).json({ valid: false, error: 'Invalid invitation token' });
        }

        const data = invitationDoc.data();

        // Check expiration
        const expiresAt = data.expiresAt.toDate ? data.expiresAt.toDate() : new Date(data.expiresAt);
        if (expiresAt < new Date()) {
            console.log(`Expired invitation: ${token}`);
            return res.status(410).json({ valid: false, error: 'Invitation has expired' });
        }

        // Check if already accepted
        if (data.status === 'accepted') {
            console.log(`Already accepted invitation: ${token}`);
            return res.status(409).json({ valid: false, error: 'Invitation already accepted' });
        }

        console.log(`Valid invitation verified: ${token}`);
        return res.json({
            valid: true,
            invitation: {
                recipientEmail: data.recipientEmail,
                recipientName: data.recipientName,
                clinicName: data.clinicName,
                clinicId: data.clinicId,
                role: data.role,
                expiresAt: data.expiresAt
            }
        });
    } catch (error) {
        console.error('Error verifying invitation:', error);
        next(error);
    }
});

// POST /invitations/accept - Accept invitation and link user to clinic
router.post('/accept', async (req, res, next) => {
    console.log('--- /invitations/accept route invoked ---');
    console.log('Request Body:', JSON.stringify(req.body, null, 2));

    const { token, userId } = req.body;

    if (!token || !userId) {
        const missingFields = [!token && "token", !userId && "userId"].filter(Boolean).join(", ");
        return res.status(400).json({
            error: `Missing required fields: ${missingFields}`
        });
    }

    try {
        const db = admin.firestore();
        const invitationRef = db.collection('invitations').doc(token);

        // Use transaction to ensure atomicity
        // Get user data from Firebase Auth BEFORE transaction
        const userRecord = await admin.auth().getUser(userId);

        await db.runTransaction(async (transaction) => {
            const invitationDoc = await transaction.get(invitationRef);

            if (!invitationDoc.exists) {
                throw new Error('Invalid invitation token');
            }

            const data = invitationDoc.data();

            // Check if already accepted
            if (data.status === 'accepted') {
                throw new Error('Invitation already accepted');
            }

            // Check expiration
            const expiresAt = data.expiresAt.toDate ? data.expiresAt.toDate() : new Date(data.expiresAt);
            if (expiresAt < new Date()) {
                throw new Error('Invitation has expired');
            }

            // Update invitation status
            transaction.update(invitationRef, {
                status: 'accepted',
                acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
                acceptedBy: userId
            });

            // Add user to clinic members
            const clinicMemberRef = db.collection('clinics')
                .doc(data.clinicId)
                .collection('members')
                .doc(userId);

            transaction.set(clinicMemberRef, {
                userId,
                email: data.recipientEmail,
                name: data.recipientName,
                role: data.role,
                addedAt: admin.firestore.FieldValue.serverTimestamp(),
                addedVia: 'invitation'
            });

            // Update user's clinics array and essential fields
            const userRef = db.collection('users').doc(userId);

            transaction.set(userRef, {
                email: userRecord.email,
                displayName: userRecord.displayName || userRecord.email?.split('@')[0] || 'User',
                photoURL: userRecord.photoURL || null,
                primaryClinicId: data.clinicId, // Set first clinic as primary
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                clinics: admin.firestore.FieldValue.arrayUnion({
                    clinicId: data.clinicId,
                    clinicName: data.clinicName,
                    role: data.role,
                    joinedAt: new Date()
                })
            }, { merge: true });

            console.log(`Invitation accepted successfully. User ${userId} added to clinic ${data.clinicId}`);
        });

        return res.json({
            success: true,
            message: 'Invitation accepted successfully'
        });
    } catch (error) {
        console.error('Error accepting invitation:', error);
        if (error.message.includes('Invalid') || error.message.includes('expired') || error.message.includes('already accepted')) {
            return res.status(400).json({
                error: error.message
            });
        }
        next(error);
    }
});

module.exports = router;