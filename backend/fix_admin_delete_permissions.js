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
const missingPermissions = [
    'deletePatient',
    'deleteSession',
    'deleteEvaluation',
    'deleteTask'
];

async function run() {
    try {
        console.log('Starting missing admin permissions patch...');

        // 1. Update Users (Global Owners)
        let ownersUpdated = 0;
        const usersSnapshot = await db.collection('users').get();
        console.log(`Scanned ${usersSnapshot.size} global users...`);

        for (const doc of usersSnapshot.docs) {
            const data = doc.data();
            const currentPermissions = data.permissions || [];
            const hasAdminIndications = data.role === 'admin' || data.role === 'owner' || currentPermissions.includes('manageSettings');

            if (hasAdminIndications) {
                const merged = [...new Set([...currentPermissions, ...missingPermissions])];
                if (merged.length !== currentPermissions.length) {
                    await doc.ref.update({ permissions: merged });
                    ownersUpdated++;
                }
            }
        }
        console.log(`✅ Updated ${ownersUpdated} global owners in users collection.`);

        // 2. Update Clinic Members (Admins & Owners)
        let membersUpdated = 0;
        const clinicsSnapshot = await db.collection('clinics').get();
        console.log(`Scanned ${clinicsSnapshot.size} clinics...`);

        for (const clinicDoc of clinicsSnapshot.docs) {
            const membersSnapshot = await clinicDoc.ref.collection('members').get();
            for (const memberDoc of membersSnapshot.docs) {
                const data = memberDoc.data();
                const role = (data.role || '').toLowerCase();
                const currentPermissions = data.permissions || [];

                const isClinicAdmin = role === 'admin' || role === 'owner' || currentPermissions.includes('manageSettings');

                if (isClinicAdmin) {
                    const merged = [...new Set([...currentPermissions, ...missingPermissions])];
                    if (merged.length !== currentPermissions.length) {
                        await memberDoc.ref.update({ permissions: merged });
                        membersUpdated++;
                        console.log(`  -> Added missing permissions to member ${memberDoc.id} in clinic ${clinicDoc.id}`);
                    }
                }
            }
        }
        console.log(`✅ Updated ${membersUpdated} clinic members.`);
        console.log('Patch complete!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error executing patch:', error);
        process.exit(1);
    }
}

run();
