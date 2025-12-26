const express = require('express');
const admin = require('firebase-admin');
const router = express.Router();

// POST /errors - Report a client-side error
router.post('/', async (req, res, next) => {
    // Log the raw request for immediate debugging/CloudWatch
    console.log('--- Error Report Received ---');
    console.log('Payload:', JSON.stringify(req.body, null, 2));

    const {
        error,
        stackTrace,
        timestamp,
        platform,
        platformVersion,
        appVersion,
        userId, // Optional: if you send user ID from client
        clinicId // Optional: if you send clinic ID from client
    } = req.body;

    if (!error) {
        return res.status(400).json({ error: 'Missing "error" field' });
    }

    try {
        // Prepare error document
        const errorData = {
            error: error.toString(),
            stackTrace: stackTrace || 'No stack trace provided',
            timestamp: timestamp || new Date().toISOString(),
            capturedAt: admin.firestore.FieldValue.serverTimestamp(),
            platform: platform || 'unknown',
            platformVersion: platformVersion || 'unknown',
            appVersion: appVersion || 'unknown',
            userAgent: req.headers['user-agent'] || 'unknown',
            ip: req.ip || req.connection.remoteAddress
        };

        if (userId) errorData.userId = userId;
        if (clinicId) errorData.clinicId = clinicId;

        // Store in Firestore
        // Using 'client_errors' collection to distinguish from backend errors
        const db = admin.firestore();
        await db.collection('client_errors').add(errorData);

        console.log('Error report stored in Firestore (client_errors)');

        return res.status(200).json({
            success: true,
            message: 'Error reported successfully'
        });

    } catch (err) {
        console.error('Failed to process error report:', err);
        // Don't fail the request if just storage fails, we still logged it
        next(err);
    }
});

// GET /errors - Retrieve errors with grouping (Crashlytics-like)
router.get('/', async (req, res, next) => {
    try {
        const db = admin.firestore();

        // Fetch all errors from last 30 days
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const snapshot = await db.collection('client_errors')
            .where('capturedAt', '>=', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
            .get();

        // Group errors by error message (like Crashlytics groups by crash type)
        const errorGroups = {};

        snapshot.forEach(doc => {
            const data = doc.data();
            const errorKey = data.error; // Group by error message

            if (!errorGroups[errorKey]) {
                errorGroups[errorKey] = {
                    error: errorKey,
                    count: 0,
                    affectedUsers: new Set(),
                    platforms: new Set(),
                    appVersions: new Set(),
                    firstSeen: data.capturedAt,
                    lastSeen: data.capturedAt,
                    instances: []
                };
            }

            const group = errorGroups[errorKey];
            group.count++;
            if (data.userId) group.affectedUsers.add(data.userId);
            if (data.platform) group.platforms.add(data.platform);
            if (data.appVersion) group.appVersions.add(data.appVersion);

            // Track first/last seen
            if (data.capturedAt < group.firstSeen) group.firstSeen = data.capturedAt;
            if (data.capturedAt > group.lastSeen) group.lastSeen = data.capturedAt;

            // Keep sample instances (limit to 5 per group)
            if (group.instances.length < 5) {
                group.instances.push({
                    id: doc.id,
                    ...data,
                    capturedAt: data.capturedAt?.toDate()?.toISOString()
                });
            }
        });

        // Convert to array and format
        const groupedErrors = Object.values(errorGroups).map(group => ({
            error: group.error,
            count: group.count,
            affectedUsers: group.affectedUsers.size,
            platforms: Array.from(group.platforms),
            appVersions: Array.from(group.appVersions),
            firstSeen: group.firstSeen?.toDate()?.toISOString(),
            lastSeen: group.lastSeen?.toDate()?.toISOString(),
            sampleInstances: group.instances
        }));

        // Sort by count (most frequent first)
        groupedErrors.sort((a, b) => b.count - a.count);

        res.json({
            success: true,
            totalGroups: groupedErrors.length,
            totalOccurrences: groupedErrors.reduce((sum, g) => sum + g.count, 0),
            groups: groupedErrors
        });
    } catch (err) {
        console.error('Failed to retrieve errors:', err);
        next(err);
    }
});

module.exports = router;
