/**
 * Migration Script: Add Tasks and Inventory Permissions
 * 
 * This script adds the new Tasks and Inventory permissions to existing users
 * based on their current role:
 * 
 * - Admin: Gets all permissions (already has them via AppPermission.values)
 * - Doctor: Gets viewAllTasks, createTask, updateTask, deleteTask
 * - Staff: Gets viewAllTasks, createTask, updateTask, viewInventory, manageInventory, adjustInventoryStock
 * - Financial: No new permissions
 * - ReadOnly: No new permissions
 */

const admin = require('firebase-admin');

// Initialize Firebase using Doppler Secret
const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccountKey) {
    console.error('Error: FIREBASE_SERVICE_ACCOUNT environment variable is missing.');
    console.error('Make sure you are running with Doppler: doppler run -- node migrate-add-tasks-inventory-permissions.js');
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

// Define new permissions by role
const NEW_PERMISSIONS_BY_ROLE = {
    admin: [
        // Admin already has all permissions via AppPermission.values, but we'll add explicitly
        'viewAllTasks',
        'viewOwnTasks',
        'createTask',
        'updateTask',
        'deleteTask',
        'viewInventory',
        'manageInventory',
        'adjustInventoryStock'
    ],
    doctor: [
        'viewAllTasks',
        'createTask',
        'updateTask',
        'deleteTask'
    ],
    staff: [
        'viewAllTasks',
        'createTask',
        'updateTask',
        'viewInventory',
        'manageInventory',
        'adjustInventoryStock'
    ],
    financial: [], // No new permissions for financial role
    readonly: []   // No new permissions for readonly role
};

async function migratePermissions() {
    console.log('🚀 Starting migration: Add Tasks and Inventory Permissions\n');

    let totalUpdated = 0;
    let totalSkipped = 0;
    let errors = 0;

    try {
        // Get all clinics
        const clinicsSnapshot = await db.collection('clinics').get();
        console.log(`📋 Found ${clinicsSnapshot.size} clinics\n`);

        for (const clinicDoc of clinicsSnapshot.docs) {
            const clinicId = clinicDoc.id;
            const clinicName = clinicDoc.data().name || clinicId;

            console.log(`\n🏥 Processing clinic: ${clinicName} (${clinicId})`);

            // Get all members in this clinic
            const membersSnapshot = await db
                .collection('clinics')
                .doc(clinicId)
                .collection('members')
                .get();

            console.log(`   👥 Found ${membersSnapshot.size} members`);

            for (const memberDoc of membersSnapshot.docs) {
                const memberId = memberDoc.id;
                const memberData = memberDoc.data();
                const role = memberData.role?.toLowerCase() || 'readonly';
                const currentPermissions = memberData.permissions || [];

                // Get new permissions for this role
                const newPermissions = NEW_PERMISSIONS_BY_ROLE[role] || [];

                if (newPermissions.length === 0) {
                    console.log(`   ⏭️  Skipped ${memberId} (Role: ${role}) - No new permissions`);
                    totalSkipped++;
                    continue;
                }

                // Check which permissions are missing
                const missingPermissions = newPermissions.filter(
                    perm => !currentPermissions.includes(perm)
                );

                if (missingPermissions.length === 0) {
                    console.log(`   ✅ ${memberId} (Role: ${role}) - Already has all permissions`);
                    totalSkipped++;
                    continue;
                }

                // Add missing permissions
                const updatedPermissions = [...currentPermissions, ...missingPermissions];

                try {
                    await db
                        .collection('clinics')
                        .doc(clinicId)
                        .collection('members')
                        .doc(memberId)
                        .update({
                            permissions: updatedPermissions
                        });

                    console.log(`   ✅ Updated ${memberId} (Role: ${role})`);
                    console.log(`      Added: ${missingPermissions.join(', ')}`);
                    totalUpdated++;
                } catch (error) {
                    console.error(`   ❌ Error updating ${memberId}:`, error.message);
                    errors++;
                }
            }
        }

        console.log('\n' + '='.repeat(60));
        console.log('Migration Complete!');
        console.log('='.repeat(60));
        console.log(`✅ Updated: ${totalUpdated} members`);
        console.log(`⏭️  Skipped: ${totalSkipped} members (already had permissions or no new permissions for role)`);
        console.log(`❌ Errors: ${errors} members`);
        console.log('='.repeat(60));

    } catch (error) {
        console.error('\n❌ Migration failed:', error);
        process.exit(1);
    }

    process.exit(0);
}

// Run migration
migratePermissions();
