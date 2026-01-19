const express = require('express');
const serverless = require('serverless-http');
const admin = require('firebase-admin');

// --- Firebase Admin Initialization ---
// This needs to be done once per container.
try {
    if (!admin.apps.length) {
        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
            console.log('Firebase Admin initialized successfully');
        } else {
            console.warn('⚠️ FIREBASE_SERVICE_ACCOUNT not set. Firebase features will not work, but static files will bloom.');
        }
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
app.use(express.static(path.join(__dirname, 'public'), {
    etag: false,
    lastModified: false,
    setHeaders: (res, path) => {
        res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
    }
}));

// Check if Firebase is initialized before loading API routes
if (admin.apps.length > 0) {
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

    // 3D Model Routes (Redirects for cleaner URLs)
    // Adding controls=false to hide the model selector bar by default for these specific routes
    app.get('/3d/body', (req, res) => res.redirect('/body_chart_3d.html?model=body&controls=false'));
    app.get('/3d/muscles', (req, res) => res.redirect('/body_chart_3d.html?model=muscles&controls=false'));
    app.get('/3d/skeleton', (req, res) => res.redirect('/body_chart_3d.html?model=skeleton&controls=false'));
    app.get('/3d/head', (req, res) => res.redirect('/body_chart_3d.html?model=head&controls=false'));
    // Updated Teeth Routes
    app.get('/3d/teeth_types', (req, res) => res.redirect('/body_chart_3d.html?model=teeth_types&controls=false'));
    app.get('/3d/upper_teeth', (req, res) => res.redirect('/body_chart_3d.html?model=upper_teeth&controls=false'));
    app.get('/3d/lower_teeth', (req, res) => res.redirect('/body_chart_3d.html?model=lower_teeth&controls=false'));
    app.get('/3d/teeth', (req, res) => res.redirect('/body_chart_3d.html?model=teeth&controls=false'));

    // API routes
    try {
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
    } catch (err) {
        console.error('Failed to load API routes:', err);
    }

    // --- Billing Kill Switch Webhook ---
    // ... (Billing logic would go here if needed, but omitted for brevity in static mode)

} else {
    console.warn('\n⚠️  RUNNING IN STATIC-ONLY MODE');
    console.warn('   - Firebase not initialized.');
    console.warn('   - API routes are DISABLED.');
    console.warn('   - 3D Body Chart assets ARE available.\n');
}

// --- Root Route for Health Check ---
app.get('/', (req, res) => {
    res.status(200).json({
        message: 'Dr. Copilot Backend is running!',
        mode: admin.apps.length > 0 ? 'Full API' : 'Static Only',
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
module.exports.handler = serverless(app);

// --- Local Development Server ---
if (require.main === module && !process.env.prod) {
    const port = process.env.PORT || 3000;
    app.listen(port, () => {
        console.log(`\n✅ Server running on port ${port}`);
        console.log(`   - API: http://localhost:${port}/api/users`);
        console.log(`   - 3D View: http://localhost:${port}/body_chart_v2.html`);
    });
}

// --- Firebase Cloud Function Export ---
const functions = require('firebase-functions');
exports.api = functions.https.onRequest(app);

// --- AWS Lambda Handler (Keep for compatibility) ---
module.exports.handler = serverless(app);
module.exports.app = app; // Export for local testing
