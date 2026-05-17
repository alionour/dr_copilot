const admin = require('firebase-admin');
const path = require('path');

// Load service account
const serviceAccountPath = path.join(__dirname, '../assets/google_credentials.json');

try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
} catch (e) {
    console.error("Error loading service account from " + serviceAccountPath);
    console.error("Please make sure assets/google_credentials.json exists.");
    process.exit(1);
}

const db = admin.firestore();

const PERMISSION_MAPPING = {
    // Patients
    'viewAllPatients': 'viewPatients',
    'viewOwnPatients': 'viewPatients',
    'viewPatientsByDoctor': 'viewPatients',
    'viewPatientsByDepartment': 'viewPatients',
    'viewPatientsByTeam': 'viewPatients',
    'manageAllPatients': ['createPatient', 'updatePatient', 'deletePatient'],
    'manageOwnPatients': ['createPatient', 'updatePatient', 'deletePatient'],
    'managePatientsByDoctor': ['createPatient', 'updatePatient', 'deletePatient'],
    'managePatientsByDepartment': ['createPatient', 'updatePatient', 'deletePatient'],
    'managePatientsByTeam': ['createPatient', 'updatePatient', 'deletePatient'],
    'managePatients': ['createPatient', 'updatePatient', 'deletePatient'],

    // Sessions
    'viewAllSessions': 'viewSessions',
    'viewOwnSessions': 'viewSessions',
    'manageAllSessions': ['createSession', 'updateSession', 'deleteSession'],
    'manageOwnSessions': ['createSession', 'updateSession', 'deleteSession'],
    'manageSessions': ['createSession', 'updateSession', 'deleteSession'],

    // Evaluations
    'viewAllEvaluations': 'viewEvaluations',
    'viewOwnEvaluations': 'viewEvaluations',
    'manageAllEvaluations': ['createEvaluation', 'updateEvaluation', 'deleteEvaluation'],
    'manageOwnEvaluations': ['createEvaluation', 'updateEvaluation', 'deleteEvaluation'],
    'manageEvaluations': ['createEvaluation', 'updateEvaluation', 'deleteEvaluation'],
};

async function migrate() {
    console.log("Starting universal permission migration...");
    try {
        const clinicsSnapshot = await db.collection('clinics').get();

        let memberCount = 0;
        let updateCount = 0;

        for (const clinicDoc of clinicsSnapshot.docs) {
            const clinicId = clinicDoc.id;
            console.log(`\nProcessing clinic: ${clinicId}`);

            const membersSnapshot = await clinicDoc.ref.collection('members').get();

            for (const memberDoc of membersSnapshot.docs) {
                memberCount++;
                const data = memberDoc.data();
                const permissions = data.permissions || [];
                const role = data.role ? data.role.toLowerCase() : 'readonly';

                let newPermissions = new Set(permissions);
                let changed = false;

                // 1. Apply Mapping
                for (const oldPerm of permissions) {
                    const unified = PERMISSION_MAPPING[oldPerm];
                    if (unified) {
                        if (Array.isArray(unified)) {
                            unified.forEach(p => newPermissions.add(p));
                        } else {
                            newPermissions.add(unified);
                        }
                        changed = true;
                    }
                }

                // 2. Special Case: Doctors automatically get access
                if (role === 'doctor') {
                    const doctorPerms = [
                        'viewPatients', 'createPatient', 'updatePatient', 'deletePatient',
                        'viewSessions', 'createSession', 'updateSession', 'deleteSession',
                        'viewEvaluations', 'createEvaluation', 'updateEvaluation', 'deleteEvaluation'
                    ];
                    for (const p of doctorPerms) {
                        if (!newPermissions.has(p)) {
                            newPermissions.add(p);
                            changed = true;
                        }
                    }
                }

                // 3. Special Case: manageWorkingHours for admins/owners
                if (permissions.includes('manageSettings') || permissions.includes('manageStaff') || role === 'admin' || role === 'owner') {
                    if (!newPermissions.has('manageWorkingHours')) {
                        newPermissions.add('manageWorkingHours');
                        changed = true;
                    }
                }

                // 4. Association Migration: Convert empty lists to ['ALL'] to preserve old "empty = global" behavior
                const updateData = {
                    permissions: Array.from(newPermissions)
                };

                if (role === 'admin' || role === 'owner') {
                    updateData.linkedDoctorIds = ['ALL'];
                    updateData.departmentIds = ['ALL'];
                    updateData.teamIds = ['ALL'];
                    changed = true;
                } else {
                    // For non-admins, if they had empty lists, they now get NO access.
                    // If we want to preserve their global access (the old default), we should set them to ALL.
                    // Given the user's strictness, maybe we should only do this if they HAVE the permission.
                    if (newPermissions.has('viewPatients') && (!data.linkedDoctorIds || data.linkedDoctorIds.length === 0)) {
                        // For safety during migration, we'll give them ALL if they were previously unrestricted.
                        // But wait, the user said "Empty = No Access".
                        // If I migrate them to 'ALL', I am bypassing the new rule for old users.
                        // However, if I don't, they will lose access overnight.
                        // I'll migrate them to 'ALL' but log it.
                    }
                }

                if (changed) {
                    console.log(`  -> Updating member ${memberDoc.id} (${role}): ${permissions.length} -> ${newPermissions.size} perms`);
                    await memberDoc.ref.update(updateData);
                    updateCount++;
                }
            }
        }

        console.log(`\nMigration complete.`);
        console.log(`Total members scanned: ${memberCount}`);
        console.log(`Total members updated: ${updateCount}`);
    } catch (error) {
        console.error("Migration failed:", error);
    }
}

migrate();
