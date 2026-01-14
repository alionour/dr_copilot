const express = require('express');
const serverless = require('serverless-http');
const admin = require('firebase-admin');

// --- Firebase Admin Initialization ---
// This needs to be done once per container.
try {
    if (!admin.apps.length) {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('Firebase Admin initialized successfully');
    }
} catch (error) {
    // Log the error but don't prevent the app from starting.
    // Routes that don't need Firebase can still run.
    console.error('Firebase Admin initialization failed:', error);
}

// --- Express App Setup ---
const app = express();
app.use(express.json());

// --- CORS Middleware ---
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS, DELETE, PUT');
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    next();
});

// --- Routes ---
// Serve static files from public directory
const path = require('path');
app.use(express.static(path.join(__dirname, 'public')));

// Serve invitation acceptance page
app.get('/accept-invitation', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'accept-invitation.html'));
});

// Serve admin notifications dashboard
app.get('/admin/notifications', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'admin-notifications.html'));
});

// Serve error dashboard
app.get('/admin/errors', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'error-dashboard.html'));
});

// API routes
const invitationRouter = require('./routes/invitations');
const notificationRouter = require('./routes/notifications');
const errorRouter = require('./routes/errors');
const bookingsRouter = require('./routes/bookings');
const subscriptionsRouter = require('./routes/subscriptions');

app.use('/invitations', invitationRouter);
app.use('/notifications', notificationRouter);
app.use('/errors', errorRouter);
app.use('/bookings', bookingsRouter);
app.use('/subscriptions', subscriptionsRouter);

// --- Billing Kill Switch Webhook ---
// Receives Pub/Sub push messages from Google Cloud Budget Alerts
const { GoogleAuth } = require('google-auth-library');
const { google } = require('googleapis');

app.post('/webhooks/billing-alert', async (req, res) => {
    try {
        if (!req.body || !req.body.message || !req.body.message.data) {
            console.warn('Invalid Pub/Sub message format');
            return res.status(400).send('Bad Request: Invalid Pub/Sub message format');
        }

        const dataString = Buffer.from(req.body.message.data, 'base64').toString();
        const data = JSON.parse(dataString);

        const costAmount = data.costAmount;
        const budgetAmount = data.budgetAmount;
        const PROJECT_ID = 'drcopilot-bfc9e'; // Hardcoded for this specific project env

        // Retrieve Admin Key from Environment Variable
        // Must be a Service Account with "Billing Account Administrator" role
        // We fallback to FIREBASE_SERVICE_ACCOUNT if specific billing key isn't set,
        // assuming the user granted the Billing Role to the default Firebase SA.
        const BILLING_ADMIN_KEY_JSON = process.env.BILLING_ADMIN_KEY_JSON || process.env.FIREBASE_SERVICE_ACCOUNT;

        console.log(`[Billing Alert] Current cost: ${costAmount}, Budget: ${budgetAmount}`);

        if (costAmount <= budgetAmount) {
            console.log('[Billing Alert] Budget not exceeded. No action.');
            return res.status(200).send('Budget safe');
        }

        if (!BILLING_ADMIN_KEY_JSON) {
            // Try to use Google Application Default Credentials if running in a compliant environment
            console.warn('[Billing Alert] No specific key found. Trying Default Credentials...');
        } else {
            console.warn('[Billing Alert] Budget EXCEEDED. Initiating KILL SWITCH...');
        }

        // Authenticate with Google
        let authClient;
        if (BILLING_ADMIN_KEY_JSON) {
            const credentials = JSON.parse(BILLING_ADMIN_KEY_JSON);
            const auth = new GoogleAuth({
                credentials,
                scopes: ['https://www.googleapis.com/auth/cloud-billing'],
            });
            authClient = await auth.getClient();
        } else {
            // Fallback to ADC (Application Default Credentials)
            const auth = new GoogleAuth({
                scopes: ['https://www.googleapis.com/auth/cloud-billing'],
            });
            authClient = await auth.getClient();
        }

        google.options({ auth: authClient });
        const cloudbilling = google.cloudbilling('v1');

        // Disable Billing
        const name = `projects/${PROJECT_ID}/billingInfo`;
        await cloudbilling.projects.updateBillingInfo({
            name: name,
            requestBody: {
                billingAccountName: '', // Remove billing account
            },
        });

        console.warn(`[Billing Alert] SUCCESS: Billing disabled for project ${PROJECT_ID}`);
        res.status(200).send('Billing Disabled Successfully');

    } catch (error) {
        console.error('[Billing Alert] Error processing webhook:', error);
        res.status(500).send('Internal Server Error');
    }
});


// --- Root Route for Health Check ---
app.get('/', (req, res) => {
    res.status(200).json({
        message: 'Dr. Copilot Backend is running!',
        timestamp: new Date().toISOString(),
        firebaseInitialized: admin.apps.length > 0,
    });
});

// --- Error Handling ---
// Handle 404 - Not Found
app.use((req, res, next) => {
    res.status(404).json({ error: 'Not Found', path: req.path });
});

// Handle other errors
app.use((error, req, res, next) => {
    console.error('An unexpected error occurred:', error);
    res.status(500).json({
        error: 'Internal Server Error',
        message: error.message
    });
});


// --- Lambda Handler ---
// Wrap the Express app with serverless-http to make it compatible with AWS Lambda
module.exports.handler = serverless(app);
module.exports.app = app; // Export for local testing
