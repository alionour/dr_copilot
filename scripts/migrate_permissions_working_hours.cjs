const admin = require('firebase-admin');
const path = require('path');

// Load service account (update path if necessary)
// Assuming running from 'scripts/' directory
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

async function migrate() {
    console.log("Starting permission migration...");
    try {
        const clinicsSnapshot = await db.collection('clinics').get();

        let updatedCount = 0;

        for (const clinicDoc of clinicsSnapshot.docs) {
            const clinicId = clinicDoc.id;
            console.log(`Processing clinic: ${clinicId}`);

            const membersSnapshot = await clinicDoc.ref.collection('members').get();

            for (const memberDoc of membersSnapshot.docs) {
                const data = memberDoc.data();
                const permissions = data.permissions || [];

                // Logic: Grant 'manageWorkingHours' to anyone who has 'manageSettings' or 'manageStaff' or 'manageDoctors'
                // This targets Admins and Owners basically.
                const shouldHavePermission = permissions.includes('manageSettings') ||
                    permissions.includes('manageStaff') ||
                    permissions.includes('manageDoctors');

                if (shouldHavePermission && !permissions.includes('manageWorkingHours')) {
                    console.log(`  -> Granting 'manageWorkingHours' to member ${memberDoc.id}`);
                    await memberDoc.ref.update({
                        permissions: admin.firestore.FieldValue.arrayUnion('manageWorkingHours')
                    });
                    updatedCount++;
                }
            }
        }

        console.log(`Migration complete. Updated ${updatedCount} members.`);
    } catch (error) {
        console.error("Migration failed:", error);
    }
}

migrate();
