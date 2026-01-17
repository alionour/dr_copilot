const admin = require('firebase-admin');

// Initialize Firebase using Doppler Secret
// We expect a secret named 'FIREBASE_SERVICE_ACCOUNT' containing the JSON string
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


// ---------------------------------------------------------
// PERMISSION DEFINITIONS
// ---------------------------------------------------------

// 1. Medical Files
const PERMS_MEDICAL = [
    'viewMedicalFiles', 'addMedicalFile', 'editMedicalFile', 'deleteMedicalFile'
];

// 2. Medications
const PERMS_MEDICATIONS = [
    'viewMedications', 'addMedication', 'editMedication', 'deleteMedication'
];

// 3. Financials
// Note: manageInvoices is deprecated but kept for safety.
const PERMS_FINANCIALS_VIEW = ['viewFinancials', 'viewReports', 'viewCharts'];
const PERMS_FINANCIALS_MANAGE = ['addFinancialEntry', 'editFinancialEntry', 'deleteFinancialEntry', 'manageInvoices'];

// 4. Recycle Bin
const PERMS_RECYCLE_BIN = [
    'viewRecycleBin', 'restoreRecycleBinItem', 'permanentDeleteRecycleBinItem'
];

// 5. Clinical Reports (New Phase 2)
const PERMS_CLINICAL_REPORTS = [
    'viewClinicalReports', 'addClinicalReport', 'editClinicalReport', 'deleteClinicalReport'
];

// 6. Doctors (New Phase 2)
const PERMS_DOCTORS = ['viewDoctors', 'manageDoctors'];

// 7. Invitations (New Phase 2)
const PERMS_INVITATIONS = ['viewInvitations', 'sendInvitation', 'revokeInvitation'];

// 8. Subscription (New Phase 2)
const PERMS_SUBSCRIPTION = ['viewSubscription', 'manageSubscription'];

// 9. Admin/Settings
const PERMS_ADMIN = [
    'manageStaff', 'manageUsers', 'assignRoles', 'assignPermissions', 'manageSettings',
    'viewSettings', 'editSettings'
];

// 10. Patients & Sessions (Legacy/Core)
const PERMS_CORE_READ = ['viewAllPatients', 'viewOwnPatients', 'viewAllSessions', 'viewOwnSessions', 'viewAllEvaluations', 'viewOwnEvaluations'];
const PERMS_CORE_WRITE = ['createPatient', 'updatePatient', 'createSession', 'updateSession', 'createEvaluation', 'updateEvaluation'];

// 11. Calendar (MISSING IN PREV RUN)
const PERMS_CALENDAR = [
    'viewCalendar', 'addCalendarEvent', 'editCalendarEvent', 'deleteCalendarEvent'
];

// 12. Teams (MISSING IN PREV RUN)
const PERMS_TEAMS = [
    'manageTeams', 'createTeam', 'archiveTeam', 'unarchiveTeam'
];

// 13. Copilot & Notifications & Help
const PERMS_MISC = [
    'useCopilot',
    'viewNotifications', 'manageNotifications', 'sendNotificationMessage', 'sendNotificationAppointment', 'sendNotificationReminder',
    'viewHelp', 'accessSupport'
];

// ---------------------------------------------------------
// ROLE MAPPINGS
// ---------------------------------------------------------

const ROLE_PERMISSIONS = {
    // 1. OWNER / ADMIN: Gets EVERYTHING
    'admin': [
        ...PERMS_MEDICAL,
        ...PERMS_MEDICATIONS,
        ...PERMS_FINANCIALS_VIEW, ...PERMS_FINANCIALS_MANAGE,
        ...PERMS_RECYCLE_BIN,
        ...PERMS_CLINICAL_REPORTS,
        ...PERMS_DOCTORS,
        ...PERMS_INVITATIONS,
        ...PERMS_SUBSCRIPTION,
        ...PERMS_ADMIN,
        ...PERMS_CALENDAR,
        ...PERMS_TEAMS,
        ...PERMS_MISC,
        ...PERMS_CORE_READ, ...PERMS_CORE_WRITE
    ],
    'owner': [ // SAME AS ADMIN
        ...PERMS_MEDICAL,
        ...PERMS_MEDICATIONS,
        ...PERMS_FINANCIALS_VIEW, ...PERMS_FINANCIALS_MANAGE,
        ...PERMS_RECYCLE_BIN,
        ...PERMS_CLINICAL_REPORTS,
        ...PERMS_DOCTORS,
        ...PERMS_INVITATIONS,
        ...PERMS_SUBSCRIPTION,
        ...PERMS_ADMIN,
        ...PERMS_CALENDAR,
        ...PERMS_TEAMS,
        ...PERMS_MISC,
        ...PERMS_CORE_READ, ...PERMS_CORE_WRITE
    ],

    // 2. DOCTOR: Medical focus, no Admin/Financial-Delete
    'doctor': [
        ...PERMS_MEDICAL, // Full medical access
        ...PERMS_MEDICATIONS, // Full meds access
        ...PERMS_CLINICAL_REPORTS, // Full reports access
        ...PERMS_CALENDAR, // Full Calendar Access
        'viewDoctors', // Can see directory
        'viewRecycleBin', // Can see bin
        'viewFinancials', 'viewReports', 'viewCharts', // Read only financials
        'useCopilot',
        'viewNotifications', 'sendNotificationMessage',
        'viewHelp', 'accessSupport',
        // Core Clinical
        'viewAllPatients', 'createPatient', 'updatePatient',
        'viewOwnSessions', 'createSession', 'updateSession',
        'viewOwnEvaluations', 'createEvaluation', 'updateEvaluation'
    ],

    // 3. STAFF / NURSE: Operational
    'staff': [
        'viewMedicalFiles', 'addMedicalFile',
        'viewMedications',
        'viewDoctors',
        'viewCalendar', 'addCalendarEvent', 'editCalendarEvent', // Scheduling
        'viewAllPatients', 'createPatient', 'updatePatient', // Front desk
        'viewAllSessions', 'createSession',
        'viewNotifications', 'viewHelp'
    ],
    'nurse': [
        'viewMedicalFiles', 'addMedicalFile', 'editMedicalFile',
        'viewMedications', 'addMedication',
        'viewDoctors',
        'viewCalendar', 'addCalendarEvent', 'editCalendarEvent',
        'viewAllPatients', 'createPatient', 'updatePatient',
        'viewAllSessions',
        'viewNotifications', 'viewHelp'
    ],

    // 4. FINANCIAL: Accountants
    'financial': [
        ...PERMS_FINANCIALS_VIEW, ...PERMS_FINANCIALS_MANAGE,
        'viewSubscription',
        'viewAllPatients',
        'viewNotifications', 'viewHelp'
    ],

    // 5. READONLY
    'readonly': [
        'viewAllPatients', 'viewOwnPatients',
        'viewAllSessions', 'viewOwnSessions',
        'viewHelp'
    ]
};

// ---------------------------------------------------------
// MIGRATION LOGIC
// ---------------------------------------------------------


async function cleanupGlobalUserPermissions() {
    console.log('Starting Cleanup of User (Global) Permissions...');
    // We previously incorrectly added permissions to the root 'users' collection.
    // We should remove them to strictly adhere to clinic-scoped permissions.
    const usersSnapshot = await db.collection('users').get();
    let batch = db.batch();
    let count = 0;

    for (const doc of usersSnapshot.docs) {
        const data = doc.data();
        if (data.permissions) {
            // Remove the 'permissions' field
            batch.update(doc.ref, { permissions: admin.firestore.FieldValue.delete() });
            count++;

            if (count >= 400) {
                await batch.commit();
                console.log(`Cleaned up permissions for ${count} users...`);
                batch = db.batch();
                count = 0;
            }
        }
    }

    if (count > 0) await batch.commit();
    console.log(`User Permissions Cleanup Complete. Removed permissions field from ${count} users.`);
}

async function migrateClinicMembers() {
    console.log('Starting Clinic Members Migration...');
    const clinicsSnapshot = await db.collection('clinics').get();
    let totalMembersUpdated = 0;

    for (const clinicDoc of clinicsSnapshot.docs) {
        const membersRef = clinicDoc.ref.collection('members');
        const membersSnapshot = await membersRef.get();

        if (membersSnapshot.empty) continue;

        let batch = db.batch();
        let count = 0;

        for (const memberDoc of membersSnapshot.docs) {
            const data = memberDoc.data();
            let role = (data.role || '').toLowerCase();

            // REVERT FIX: Migrate 'owner' back to 'admin' per user request
            if (role === 'owner') {
                console.log(`   - Migrating user ${memberDoc.id} from 'owner' back to 'admin'`);
                role = 'admin';
                batch.update(memberDoc.ref, { role: 'admin' });
            }

            // Ensure 'admin' has the exact same permissions as the previous 'owner' concept
            const permissions = ROLE_PERMISSIONS[role] || [];

            if (permissions.length > 0) {
                // Deduplicate just in case
                const uniquePerms = [...new Set(permissions)];
                batch.update(memberDoc.ref, { permissions: uniquePerms });
                count++;
                totalMembersUpdated++;
            }

            if (count >= 400) {
                await batch.commit();
                batch = db.batch();
                count = 0;
            }
        }

        if (count > 0) await batch.commit();
    }
    console.log(`Clinic Members Migration Complete. Updated ${totalMembersUpdated} members across all clinics.`);
}

async function run() {
    try {
        await cleanupGlobalUserPermissions(); // Clean up the mistake
        await migrateClinicMembers(); // Ensure members are correct
        console.log('✅ UNIVERSAL PERMISSIONS MIGRATION (CORRECTED) SUCCESSFUL');
        process.exit(0);
    } catch (error) {
        console.error('❌ Migration Failed:', error);
        process.exit(1);
    }
}

run();
