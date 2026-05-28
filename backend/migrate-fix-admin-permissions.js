/**
 * Migration Script: Update Administrative and Booking Permissions
 * 
 * This script ensures all clinic members have the latest permissions based on their roles.
 * It's especially important for admins (owners) to have all AppPermission values.
 */

const admin = require('firebase-admin');

// Initialize Firebase using Doppler Secret
const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccountKey) {
    console.error('Error: FIREBASE_SERVICE_ACCOUNT environment variable is missing.');
    console.error('Make sure you are running with Doppler: doppler run -- node migrate-fix-admin-permissions.js');
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

// FULL list of current permissions to ensure admins are truly up to date
const ALL_PERMISSIONS = [
    'viewPatients', 'createPatient', 'updatePatient', 'deletePatient',
    'viewSessions', 'createSession', 'updateSession', 'deleteSession',
    'viewEvaluations', 'createEvaluation', 'updateEvaluation', 'deleteEvaluation',
    'viewFinancials', 'addFinancialEntry', 'editFinancialEntry', 'deleteFinancialEntry',
    'useCopilot', 'viewCalendar', 'addCalendarEvent', 'editCalendarEvent', 'deleteCalendarEvent',
    'viewNotifications', 'manageNotifications', 'viewSettings', 'editSettings', 'manageSettings',
    'manageStaff', 'manageUsers', 'assignRoles', 'assignPermissions',
    'viewReports', 'viewCharts', 'viewMedicalFiles', 'createMedicalFile', 'updateMedicalFile', 'deleteMedicalFile',
    'viewMedications', 'addMedication', 'editMedication', 'deleteMedication',
    'viewRecycleBin', 'restoreRecycleBinItem', 'permanentDeleteRecycleBinItem',
    'viewClinicalReports', 'createClinicalReport', 'updateClinicalReport', 'deleteClinicalReport',
    'viewDoctors', 'manageDoctors', 'viewInvitations', 'sendInvitation', 'revokeInvitation',
    'viewSubscription', 'manageSubscription', 'viewHelp', 'accessSupport',
    'sendNotificationMessage', 'sendNotificationAppointment', 'sendNotificationReminder',
    'viewTeams', 'manageTeams', 'createTeam', 'archiveTeam', 'unarchiveTeam',
    'viewTeamMembers', 'viewTeamMessages', 'viewInventory', 'manageInventory', 'adjustInventoryStock',
    'viewDepartments', 'manageDepartments', 'manageWorkingHours', 'manageBookingAvailability',
    'viewAllTasks', 'viewOwnTasks', 'createTask', 'updateTask', 'deleteTask'
];

async function migratePermissions() {
    console.log('🚀 Starting migration: Comprehensive Permission Fix\n');

    let totalUpdated = 0;
    let totalSkipped = 0;
    let errors = 0;

    try {
        const clinicsSnapshot = await db.collection('clinics').get();
        console.log(`📋 Found ${clinicsSnapshot.size} clinics\n`);

        for (const clinicDoc of clinicsSnapshot.docs) {
            const clinicId = clinicDoc.id;
            const clinicName = clinicDoc.data().name || clinicId;

            console.log(`\n🏥 Processing clinic: ${clinicName} (${clinicId})`);

            const membersSnapshot = await db
                .collection('clinics')
                .doc(clinicId)
                .collection('members')
                .get();

            for (const memberDoc of membersSnapshot.docs) {
                const memberId = memberDoc.id;
                const memberData = memberDoc.data();
                const role = memberData.role?.toLowerCase() || 'readonly';
                
                // We focus on fixing Admins to have ALL permissions
                if (role !== 'admin') {
                    totalSkipped++;
                    continue;
                }

                const currentPermissions = memberData.permissions || [];
                
                // Check if admin is missing any permissions from the master list
                const missingPermissions = ALL_PERMISSIONS.filter(
                    perm => !currentPermissions.includes(perm)
                );

                if (missingPermissions.length === 0) {
                    console.log(`   ✅ Admin ${memberId} - Already has all permissions`);
                    totalSkipped++;
                    continue;
                }

                try {
                    await db
                        .collection('clinics')
                        .doc(clinicId)
                        .collection('members')
                        .doc(memberId)
                        .update({
                            permissions: ALL_PERMISSIONS
                        });

                    console.log(`   ✅ Updated Admin ${memberId}`);
                    console.log(`      Added: ${missingPermissions.join(', ')}`);
                    totalUpdated++;
                } catch (error) {
                    console.error(`   ❌ Error updating Admin ${memberId}:`, error.message);
                    errors++;
                }
            }
        }

        console.log('\n' + '='.repeat(60));
        console.log('Migration Complete!');
        console.log('='.repeat(60));
        console.log(`✅ Updated: ${totalUpdated} members`);
        console.log(`⏭️  Skipped: ${totalSkipped} members`);
        console.log(`❌ Errors: ${errors} members`);
        console.log('='.repeat(60));

    } catch (error) {
        console.error('\n❌ Migration failed:', error);
        process.exit(1);
    }

    process.exit(0);
}

migratePermissions();
