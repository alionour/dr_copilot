const admin = require('firebase-admin');

// --- Firebase Admin Initialization ---
// Ensure Firebase Admin is initialized. 
// Note: In the main index.js, it's initialized, but Lambda functions might run in separate contexts if deployed individually.
// However, since we are using the same serverless deployment, we can reuse the initialization if we import this module into the main handler or keep it standalone.
// For a standalone scheduled function, it's safer to ensure initialization here or rely on the shared runtime if managed correctly.
// Given the existing structure, let's play it safe and check/init.

if (!admin.apps.length) {
    try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('Firebase Admin initialized in recycle-bin-cleanup');
    } catch (e) {
        console.error('Failed to initialize Firebase Admin:', e);
        // If we can't init, we can't do anything.
        process.exit(1);
    }
}

module.exports.handler = async (event) => {
    console.log('Recycle Bin Cleanup started');
    const db = admin.firestore();

    // Calculate the threshold date: 30 days ago
    const now = new Date();
    const thresholdDate = new Date(now.setDate(now.getDate() - 30));
    const thresholdTimestamp = admin.firestore.Timestamp.fromDate(thresholdDate);

    console.log(`Cleaning up items deleted before: ${thresholdDate.toISOString()}`);

    const collections = ['evaluations', 'sessions'];
    let totalDeleted = 0;

    try {
        for (const collectionName of collections) {
            console.log(`Checking collection: ${collectionName}`);

            // Query for items where deletedAt < threshold
            // Note: We need to filter where deletedAt is NOT NULL implicitly by the comparison,
            // but explicitly checking isNull logic isn't needed with < operator if fields are missing (they won't match),
            // however, to be safe and use an index efficiently:
            // We want: deletedAt is not null AND deletedAt < threshold.

            const snapshot = await db.collection(collectionName)
                .where('deletedAt', '<', thresholdTimestamp)
                .get();

            if (snapshot.empty) {
                console.log(`No old deleted items found in ${collectionName}`);
                continue;
            }

            console.log(`Found ${snapshot.size} items to permanently delete in ${collectionName}`);

            // Batch delete
            const batch = db.batch();
            let batchCount = 0;

            for (const doc of snapshot.docs) {
                batch.delete(doc.ref);
                batchCount++;
                totalDeleted++;
            }

            // Commit batch
            await batch.commit();
            console.log(`Batch commit successful for ${collectionName}`);
        }

        console.log(`Recycle Bin Cleanup completed. Total items permanently deleted: ${totalDeleted}`);
        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Cleanup complete', totalDeleted }),
        };

    } catch (error) {
        console.error('Error during Recycle Bin Cleanup:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message }),
        };
    }
};
