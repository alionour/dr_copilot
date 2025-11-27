const admin = require('firebase-admin');
const serviceAccount = require('./drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const OWNER_ID = 'ktmgVQ0iJdN2WzhnPCWS4MC4rRz1';
const DOCTOR_ID = 'bQtBDHZwU8e0xiiCzRcRDxqc5S32';

async function assignRoles() {
    console.log('Assigning roles...');
    const batch = db.batch();

    // Assign 'owner' role
    const ownerRef = db.collection('users').doc(OWNER_ID);
    batch.update(ownerRef, { role: 'owner' });
    console.log(`Queued update for Owner (${OWNER_ID}) -> role: 'owner'`);

    // Assign 'doctor' role
    const doctorRef = db.collection('users').doc(DOCTOR_ID);
    batch.update(doctorRef, { role: 'doctor' });
    console.log(`Queued update for Doctor (${DOCTOR_ID}) -> role: 'doctor'`);

    await batch.commit();
    console.log('Roles assigned successfully.');
}

assignRoles().catch(console.error);
