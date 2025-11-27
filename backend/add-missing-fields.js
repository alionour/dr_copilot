const admin = require('firebase-admin');
const serviceAccount = require('./drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addMissingFields() {
    console.log('--- ADDING MISSING FIELDS TO USERS ---\n');

    try {
        const usersSnapshot = await db.collection('users').get();
        let updatedCount = 0;

        for (const userDoc of usersSnapshot.docs) {
            const data = userDoc.data();
            const updateData = {};
            let needsUpdate = false;

            // Get user from Firebase Auth
            let userRecord;
            try {
                userRecord = await admin.auth().getUser(userDoc.id);
            } catch (error) {
                console.log(`⚠️  User ${userDoc.id} not found in Firebase Auth, skipping...`);
                continue;
            }

            // Check and add missing email
            if (!data.email && userRecord.email) {
                updateData.email = userRecord.email;
                needsUpdate = true;
            }

            // Check and add missing displayName
            if (!data.displayName) {
                updateData.displayName = userRecord.displayName ||
                    userRecord.email?.split('@')[0] ||
                    'User';
                needsUpdate = true;
            }

            // Check and add missing photoURL
            if (!data.photoURL && userRecord.photoURL) {
                updateData.photoURL = userRecord.photoURL;
                needsUpdate = true;
            }

            // Check and add missing createdAt
            if (!data.createdAt) {
                // Use Firebase Auth creation time if available
                const creationTime = userRecord.metadata.creationTime;
                updateData.createdAt = creationTime ? new Date(creationTime) : new Date();
                needsUpdate = true;
            }

            // Check and add missing primaryClinicId
            if (!data.primaryClinicId && data.clinics && data.clinics.length > 0) {
                updateData.primaryClinicId = data.clinics[0].clinicId;
                needsUpdate = true;
            }

            if (needsUpdate) {
                console.log(`Updating user: ${userDoc.id} (${data.email || userRecord.email || 'No Email'})`);
                console.log(`  Adding: ${Object.keys(updateData).join(', ')}`);

                await userDoc.ref.update(updateData);
                updatedCount++;
            }
        }

        console.log('\n--- UPDATE SUMMARY ---');
        if (updatedCount === 0) {
            console.log('✅ All users have required fields!');
        } else {
            console.log(`✅ Updated ${updatedCount} user(s) with missing fields`);
        }

    } catch (error) {
        console.error('❌ Error adding missing fields:', error);
    }
}

addMissingFields();
