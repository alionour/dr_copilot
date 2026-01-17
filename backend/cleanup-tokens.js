const admin = require('firebase-admin');
const serviceAccount = require('./drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupTokens() {
    console.log('--- CLEANING UP TOKENS FROM FIRESTORE ---\n');

    try {
        const usersSnapshot = await db.collection('users').get();
        let cleanedCount = 0;

        for (const userDoc of usersSnapshot.docs) {
            const data = userDoc.data();

            // Check if user has tokens stored (they shouldn't)
            if (data.accessToken || data.idToken) {
                console.log(`Cleaning tokens for user: ${userDoc.id} (${data.email || 'No Email'})`);

                // Remove token fields
                const updateData = {};
                if (data.accessToken) {
                    updateData.accessToken = admin.firestore.FieldValue.delete();
                }
                if (data.idToken) {
                    updateData.idToken = admin.firestore.FieldValue.delete();
                }

                await userDoc.ref.update(updateData);
                console.log(`✅ Removed tokens from ${userDoc.id}\n`);
                cleanedCount++;
            }
        }

        if (cleanedCount === 0) {
            console.log('✅ No tokens found in Firestore. All clean!');
        } else {
            console.log(`\n🎉 Successfully cleaned ${cleanedCount} user(s).`);
        }

    } catch (error) {
        console.error('❌ Error cleaning tokens:', error);
    }
}

cleanupTokens();
