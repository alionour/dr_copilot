const admin = require('firebase-admin');
const serviceAccount = require('./drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Fields to remove from user documents
const FIELDS_TO_REMOVE = [
    'accessToken',
    'idToken',
    'roles',
    'permissions',
    'ownerId',
    'metadata',
    'providerData',
    'phoneNumber',
    'emailVerified',
    'isAnonymous',
    'refreshToken',
    'tenantId',
    'clinicIds' // Legacy field, replaced by clinics array
];

async function cleanupSchema() {
    console.log('--- CLEANING UP USER SCHEMA ---\n');

    try {
        const usersSnapshot = await db.collection('users').get();
        let cleanedCount = 0;
        let fieldsRemoved = {};

        for (const userDoc of usersSnapshot.docs) {
            const data = userDoc.data();
            const updateData = {};
            let hasFieldsToRemove = false;

            // Check which fields need to be removed
            for (const field of FIELDS_TO_REMOVE) {
                if (data[field] !== undefined) {
                    updateData[field] = admin.firestore.FieldValue.delete();
                    hasFieldsToRemove = true;
                    fieldsRemoved[field] = (fieldsRemoved[field] || 0) + 1;
                }
            }

            if (hasFieldsToRemove) {
                console.log(`Cleaning user: ${userDoc.id} (${data.email || 'No Email'})`);
                console.log(`  Removing: ${Object.keys(updateData).join(', ')}`);

                await userDoc.ref.update(updateData);
                cleanedCount++;
            }
        }

        console.log('\n--- CLEANUP SUMMARY ---');
        if (cleanedCount === 0) {
            console.log('✅ No fields to clean. Schema is already clean!');
        } else {
            console.log(`✅ Cleaned ${cleanedCount} user(s)`);
            console.log('\nFields removed:');
            for (const [field, count] of Object.entries(fieldsRemoved)) {
                console.log(`  - ${field}: ${count} user(s)`);
            }
        }

    } catch (error) {
        console.error('❌ Error cleaning schema:', error);
    }
}

cleanupSchema();
