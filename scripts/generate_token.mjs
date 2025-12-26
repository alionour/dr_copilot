import admin from 'firebase-admin';

const TESTER_UID = '6QEq5hMazPaegl2rGwulSgGdXPw1';

// Parse service account from environment variable
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT || '{}');

if (!serviceAccount.project_id) {
    console.error('Error: FIREBASE_SERVICE_ACCOUNT env var is missing or invalid.');
    process.exit(1);
}

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

import fs from 'fs';

async function generateToken() {
    try {
        const customToken = await admin.auth().createCustomToken(TESTER_UID);
        fs.writeFileSync('token.txt', customToken);
        console.log('Token written to token.txt');
    } catch (error) {
        console.error('Error creating custom token:', error);
        process.exit(1);
    }
}

generateToken();
