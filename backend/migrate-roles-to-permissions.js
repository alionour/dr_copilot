const admin = require('firebase-admin');
const serviceAccount = require('./drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define Role to Permissions Mapping (Must match RoleDefaults in Dart code)
const ROLE_PERMISSIONS = {
    'admin': [
        'viewAllPatients', 'viewOwnPatients', 'createPatient', 'updatePatient', 'deletePatient',
        'viewAllSessions', 'viewOwnSessions', 'createSession', 'updateSession', 'deleteSession',
        'viewAllEvaluations', 'viewOwnEvaluations', 'createEvaluation', 'updateEvaluation', 'deleteEvaluation',
        'viewFinancials', 'manageInvoices',
        'manageStaff', 'manageSettings'
    ],
    'doctor': [
        'viewAllPatients', 'createPatient', 'updatePatient',
        'viewOwnSessions', 'createSession', 'updateSession',
        'viewOwnEvaluations', 'createEvaluation', 'updateEvaluation'
    ],
    'staff': [
        'viewAllPatients', 'createPatient', 'updatePatient',
        'viewAllSessions', 'createSession'
    ],
    'financial': [
        'viewFinancials', 'manageInvoices'
    ],
    'readonly': [
        'viewAllPatients', 'viewAllSessions'
    ]
};

async function migrateUsers() {
    console.log('Starting Users Migration...');
    const usersSnapshot = await db.collection('users').get();
    let batch = db.batch();
    let count = 0;

    for (const doc of usersSnapshot.docs) {
        const data = doc.data();
        if (data.clinics && Array.isArray(data.clinics)) {
            let updated = false;
            const updatedClinics = data.clinics.map(clinic => {
                if (clinic.role) {
                    const roleLower = clinic.role.toLowerCase();
                    const permissions = ROLE_PERMISSIONS[roleLower] || [];
                    // Always update permissions to ensure they are current
                    clinic.permissions = permissions;
                    updated = true;
                }
                return clinic;
            });

            if (updated) {
                batch.update(doc.ref, { clinics: updatedClinics });
                count++;
                if (count % 500 === 0) {
                    await batch.commit();
                    batch = db.batch();
                    console.log(`Committed batch of ${count} users...`);
                }
            }
        }
    }

    if (count > 0) {
        await batch.commit();
    }
    console.log(`Users Migration Complete. Updated ${count} users.`);
}

async function migrateMembers() {
    console.log('Starting Members Migration...');
    const clinicsSnapshot = await db.collection('clinics').get();

    for (const clinicDoc of clinicsSnapshot.docs) {
        const membersSnapshot = await clinicDoc.ref.collection('members').get();
        if (membersSnapshot.empty) continue;

        let batch = db.batch();
        let count = 0;

        for (const memberDoc of membersSnapshot.docs) {
            const data = memberDoc.data();
            if (data.role) {
                const roleLower = data.role.toLowerCase();
                const permissions = ROLE_PERMISSIONS[roleLower] || [];

                batch.update(memberDoc.ref, { permissions: permissions });
                count++;

                if (count % 500 === 0) {
                    await batch.commit();
                    batch = db.batch();
                }
            }
        }

        if (count > 0) {
            await batch.commit();
            console.log(`Updated ${count} members in clinic ${clinicDoc.id}`);
        }
    }
    console.log('Members Migration Complete.');
}

async function runMigration() {
    try {
        await migrateUsers();
        await migrateMembers();
        console.log('All migrations finished successfully.');
    } catch (error) {
        console.error('Migration failed:', error);
    }
}

runMigration();
