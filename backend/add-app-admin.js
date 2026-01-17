// Add admin to appAdmins collection
const admin = require('firebase-admin');

// Initialize Firebase Admin from environment variable
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addAdmin() {
    const adminEmail = 'nourrehabcenter@gmail.com';

    try {
        await db.collection('appAdmins').doc(adminEmail).set({
            email: adminEmail,
            displayName: 'Ali Nour',
            addedAt: admin.firestore.FieldValue.serverTimestamp(),
            addedBy: 'system'
        });

        console.log('✅ Successfully added admin:', adminEmail);
        console.log('You can now access the dashboard at:');
        console.log('https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/admin/notifications');

    } catch (error) {
        console.error('❌ Error adding admin:', error);
    }

    process.exit(0);
}

addAdmin();
