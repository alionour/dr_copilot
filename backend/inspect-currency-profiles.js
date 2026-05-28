const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    }
}

const db = admin.firestore();

async function run() {
    console.log('--- ALL CLINICS ---');
    try {
        const snap = await db.collection('clinics').get();
        console.log(`Found ${snap.size} clinics:`);
        snap.forEach(doc => {
            console.log(`- Clinic ID: ${doc.id}, Name: ${doc.data().name}`);
        });
    } catch (e) {
        console.error(e);
    }
}

run();
