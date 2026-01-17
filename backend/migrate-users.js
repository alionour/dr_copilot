const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateUsers() {
    console.log('--- MIGRATING USERS ---\n');

    try {
        const usersSnapshot = await db.collection('users').get();
        let migratedCount = 0;

        for (const userDoc of usersSnapshot.docs) {
            const data = userDoc.data();

            // Check if migration is needed: Has clinicIds but NO clinics
            if (data.clinicIds && data.clinicIds.length > 0 && (!data.clinics || data.clinics.length === 0)) {

                console.log(`Migrating User: ${userDoc.id} (${data.email || 'No Email'})`);

                const newClinics = [];

                for (const clinicId of data.clinicIds) {
                    // Fetch clinic name to be nice
                    const clinicDoc = await db.collection('clinics').doc(clinicId).get();
                    const clinicName = clinicDoc.exists ? clinicDoc.data().name : 'Unknown Clinic';

                    newClinics.push({
                        clinicId: clinicId,
                        clinicName: clinicName,
                        role: 'Admin', // Default to Admin as requested
                        joinedAt: new Date()
                    });
                }

                // Update User
                await userDoc.ref.update({ clinics: newClinics });
                console.log(`✅ Updated ${userDoc.id} with ${newClinics.length} clinics.\n`);
                migratedCount++;
            }
        }

        if (migratedCount === 0) {
            console.log('No users needed migration.');
        } else {
            console.log(`\n🎉 Successfully migrated ${migratedCount} users.`);
        }

    } catch (error) {
        console.error('Error migrating users:', error);
    }
}

migrateUsers();
