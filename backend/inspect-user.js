const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function inspect() {
    console.log('--- INSPECTING FIRESTORE DATA ---\n');

    try {
        // 1. Inspect the Owner (Legacy User)
        const ownerId = 'ktmgVQ0iJdN2WzhnPCWS4MC4rRz1';
        const ownerDoc = await db.collection('users').doc(ownerId).get();

        if (ownerDoc.exists) {
            const data = ownerDoc.data();
            console.log(`USER: Owner (${ownerId})`);
            console.log('----------------------------------------');
            console.log('clinicIds (Expected by App):', JSON.stringify(data.clinicIds, null, 2));
            console.log('clinics   (New Structure):  ', JSON.stringify(data.clinics, null, 2));
            console.log('\n');
        } else {
            console.log(`Owner ${ownerId} not found.\n`);
        }

        // 2. Inspect the Newest User (Invited Doctor)
        // We'll look for users created in the last 24 hours or just the last one
        const snapshot = await db.collection('users')
            .orderBy('createdAt', 'desc') // Assuming createdAt exists
            .limit(1)
            .get();

        if (!snapshot.empty) {
            const newUser = snapshot.docs[0];
            const data = newUser.data();
            console.log(`USER: Newest User (${newUser.id})`);
            console.log('----------------------------------------');
            console.log('clinicIds (Expected by App):', JSON.stringify(data.clinicIds, null, 2));
            console.log('clinics   (New Structure):  ', JSON.stringify(data.clinics, null, 2));
        } else {
            console.log('No users found.');
        }
    } catch (error) {
        console.error('Error inspecting database:', error);
    }
}

inspect();
