const admin = require('firebase-admin');

// Initialize Firebase using Doppler Secret
const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccountKey) {
    console.error('Error: FIREBASE_SERVICE_ACCOUNT environment variable is missing.');
    console.error('Make sure you are running with Doppler: doppler run -- node backend/apply-universal-permissions.js');
    process.exit(1);
}

try {
    const serviceAccount = JSON.parse(serviceAccountKey);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
} catch (error) {
    console.error('Error parsing FIREBASE_SERVICE_ACCOUNT JSON:', error);
    process.exit(1);
}

const db = admin.firestore();

const ROLE_PERMISSIONS = {
    'staff': [
        'viewPatients', 'createPatient', 'updatePatient', 'deletePatient',
        'viewSessions', 'createSession', 'updateSession', 'deleteSession',
        'viewEvaluations', 'createEvaluation', 'updateEvaluation', 'deleteEvaluation',
        'viewMedicalFiles', 'createMedicalFile', 'updateMedicalFile', 'deleteMedicalFile',
        'viewMedications', 'addMedication', 'editMedication', 'deleteMedication',
        'viewCalendar', 'addCalendarEvent', 'editCalendarEvent', 'deleteCalendarEvent',
        'viewNotifications', 'viewHelp',
        'viewDepartments', 'viewTeams',
        'assignPermissions'
    ],
};

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
    console.log("Starting universal permission and association migration...");
    try {
        const clinicsSnapshot = await db.collection('clinics').get();

        let memberCount = 0;
        let updateCount = 0;

        for (const clinicDoc of clinicsSnapshot.docs) {
            const clinicId = clinicDoc.id;
            const clinicName = clinicDoc.data().name || 'Unnamed';
            console.log(`\nProcessing clinic: ${clinicId} (${clinicName})`);

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
                            unified.forEach(p => newPermissions.has(p) || (newPermissions.add(p), changed = true));
                        } else {
                            if (!newPermissions.has(unified)) {
                                newPermissions.add(unified);
                                changed = true;
                            }
                        }
                    }
                }

                // 2. Special Case: Specific Role Defaults
                if (ROLE_PERMISSIONS[role]) {
                    ROLE_PERMISSIONS[role].forEach(p => {
                        if (!newPermissions.has(p)) {
                            newPermissions.add(p);
                            changed = true;
                        }
                    });
                }

                // 3. Special Case: Doctors automatically get granular clinical access
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

                // 4. Association Migration
                let updateData = {
                    permissions: Array.from(newPermissions)
                };

                // Admins and Owners get 'ALL' access to preserve global behavior
                if (role === 'admin' || role === 'owner') {
                    if (!data.linkedDoctorIds || !data.linkedDoctorIds.includes('ALL')) {
                        updateData.linkedDoctorIds = ['ALL'];
                        changed = true;
                    }
                    if (!data.departmentIds || !data.departmentIds.includes('ALL')) {
                        updateData.departmentIds = ['ALL'];
                        changed = true;
                    }
                    if (!data.teamIds || !data.teamIds.includes('ALL')) {
                        updateData.teamIds = ['ALL'];
                        changed = true;
                    }
                } else if (role === 'doctor') {
                    // Doctors should be linked to themselves if not already
                    const doctorIds = data.linkedDoctorIds || [];
                    if (!doctorIds.includes(memberDoc.id)) {
                        updateData.linkedDoctorIds = [...doctorIds, memberDoc.id];
                        changed = true;
                    }
                } else {
                    // For Staff/Readonly:
                    // If they previously had empty lists (which meant ALL), 
                    // we migrate them to ['ALL'] if they have clinical view permissions,
                    // OR we leave them empty if they were meant to be restricted.
                    // Given the old system defaulted to ALL, we'll assign 'ALL' to avoid breakage,
                    // but ONLY if the lists are truly missing or empty.
                    
                    if (newPermissions.has('viewPatients')) {
                        if (!data.linkedDoctorIds || data.linkedDoctorIds.length === 0) {
                            updateData.linkedDoctorIds = ['ALL'];
                            changed = true;
                        }
                        if (!data.departmentIds || data.departmentIds.length === 0) {
                            updateData.departmentIds = ['ALL'];
                            changed = true;
                        }
                        if (!data.teamIds || data.teamIds.length === 0) {
                            updateData.teamIds = ['ALL'];
                            changed = true;
                        }
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
        process.exit(1);
    }
}

migrate().then(() => process.exit(0));
