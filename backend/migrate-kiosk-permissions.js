const admin = require('firebase-admin');
const fs = require('fs');

let serviceAccount;

// 1. Try Environment Variable (Doppler)
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
        console.log('Reading credentials from FIREBASE_SERVICE_ACCOUNT...');
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (e) {
        console.error('Error parsing FIREBASE_SERVICE_ACCOUNT:', e);
    }
}

// 2. Fallback to local file
if (!serviceAccount) {
    try {
        console.log('Reading credentials from local file...');
        // Use relative path since we are running from backend folder
        serviceAccount = require('./drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');
    } catch (e) {
        console.warn('Local credentials file not found or invalid.');
    }
}

if (!serviceAccount) {
    console.error('FATAL: No valid Firebase credentials found.');
    console.error('Please run with: doppler run -- node migrate-kiosk-permissions.js');
    process.exit(1);
}

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migratePermissions() {
    console.log('Starting permission migration for Kiosk features...');

    try {
        const clinicsSnapshot = await db.collection('clinics').get();
        let updatedCount = 0;

        for (const clinicDoc of clinicsSnapshot.docs) {
            const clinicId = clinicDoc.id;
            console.log(`Processing clinic: ${clinicId}`);

            const membersSnapshot = await clinicDoc.ref.collection('members').get();

            for (const memberDoc of membersSnapshot.docs) {
                const memberData = memberDoc.data();
                const role = memberData.role;
                const currentPermissions = memberData.permissions || [];

                // Add 'manageSettings' to Owners and Admins
                if (role === 'owner' || role === 'admin') {
                    if (!currentPermissions.includes('manageSettings')) {
                        console.log(`  - Adding 'manageSettings' to user ${memberDoc.id} (${role})`);

                        await memberDoc.ref.update({
                            permissions: admin.firestore.FieldValue.arrayUnion('manageSettings')
                        });
                        updatedCount++;
                    }
                }
            }
        }

        console.log(`Migration complete. Updated ${updatedCount} members.`);
    } catch (error) {
        console.error('Migration failed:', error);
    }
}

migratePermissions();
