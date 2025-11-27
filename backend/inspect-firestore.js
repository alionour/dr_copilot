const admin = require('firebase-admin');
const serviceAccount = require('./drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function inspectCollection(collectionName) {
    console.log(`\n--- INSPECTING: ${collectionName} ---`);
    try {
        const snapshot = await db.collection(collectionName).limit(1).get();
        if (snapshot.empty) {
            console.log('  [EMPTY COLLECTION]');
            return;
        }

        const doc = snapshot.docs[0];
        console.log(`  Document ID: ${doc.id}`);
        console.log('  Fields:');
        const data = doc.data();
        Object.keys(data).forEach(key => {
            let valuePreview = JSON.stringify(data[key]);
            if (valuePreview && valuePreview.length > 50) {
                valuePreview = valuePreview.substring(0, 50) + '...';
            }
            console.log(`    - ${key}: ${valuePreview}`);
        });

    } catch (error) {
        console.error(`  Error inspecting ${collectionName}:`, error);
    }
}

async function runInspection() {
    await inspectCollection('users');
    await inspectCollection('clinics');
    await inspectCollection('patients');
    await inspectCollection('sessions');
    await inspectCollection('evaluations');
}

runInspection();
