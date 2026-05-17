const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('Firebase Admin initialized successfully');
    } else {
        console.error('FIREBASE_SERVICE_ACCOUNT environment variable not set');
        process.exit(1);
    }
}

const db = admin.firestore();
const uid = 'BxEqFqS2AwUCtas3zgZtgM3iErt1';
const clinicId = 'n8GSKcqC5J2ijANI3cDU';

// Permissions that staff/receptionist must have to use the Add Evaluation page
const requiredPermissions = [
    'viewDoctors',
    'viewEvaluations',
    'createEvaluation',
];

async function fixReceptionistPermissions() {
    try {
        const memberRef = db.collection('clinics').doc(clinicId).collection('members').doc(uid);
        const memberDoc = await memberRef.get();

        if (!memberDoc.exists) {
            console.error('❌ Member document not found!');
            process.exit(1);
        }

        const existing = memberDoc.data();
        const currentPermissions = existing.permissions || [];
        console.log(`Current permissions count: ${currentPermissions.length}`);

        // Merge missing permissions
        const merged = [...new Set([...currentPermissions, ...requiredPermissions])];
        console.log(`New permissions count: ${merged.length}`);
        console.log(`Added: ${merged.filter(p => !currentPermissions.includes(p)).join(', ')}`);

        await memberRef.update({ permissions: merged });
        console.log('✅ Permissions updated successfully!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

fixReceptionistPermissions();
