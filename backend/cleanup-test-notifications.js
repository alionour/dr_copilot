// Delete invalid sample notifications that use 'all_users' target type
const admin = require('firebase-admin');

// Initialize Firebase Admin from environment variable
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

if (admin.apps.length === 0) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();

async function cleanupInvalidNotifications() {
    console.log('🧹 Cleaning up invalid sample notifications...\n');

    try {
        // Query for test notifications (those with isTestData metadata)
        const notificationsRef = db.collection('notifications');
        const snapshot = await notificationsRef
            .where('metadata.isTestData', '==', true)
            .get();

        if (snapshot.empty) {
            console.log('No test notifications found.');
            process.exit(0);
        }

        console.log(`Found ${snapshot.size} test notification(s) to delete.\n`);

        const batch = db.batch();
        let deleteCount = 0;

        snapshot.docs.forEach(doc => {
            const data = doc.data();
            console.log(`🗑️  Deleting: "${data.title}"`);
            batch.delete(doc.ref);
            deleteCount++;
        });

        await batch.commit();

        console.log(`\n✅ Successfully deleted ${deleteCount} test notification(s).`);
        console.log('Your notifications tab should now work without errors.\n');

    } catch (error) {
        console.error('❌ Error cleaning up notifications:', error);
    }

    process.exit(0);
}

cleanupInvalidNotifications();
