const admin = require('firebase-admin');
const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccountKey) {
    console.error('Error: FIREBASE_SERVICE_ACCOUNT environment variable is missing.');
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

async function diagnose() {
    const emailToDebug = 'drcopilot.test@gmail.com'; // Adjust if needed
    console.log(`\n🔍 DIAGNOSING PERMISSIONS FOR: ${emailToDebug}`);

    // 1. Find User by Email (Auth & Firestore)
    let uid;
    try {
        const userRecord = await admin.auth().getUserByEmail(emailToDebug);
        console.log(`\n✅ Auth User Found: UID=${userRecord.uid}`);
        uid = userRecord.uid;
    } catch (e) {
        console.error(`\n❌ User not found in Firebase Auth by email: ${e.message}`);
        // Try to search Firestore users collection by email if Auth fails?
        // Usually Auth is source of truth.
        return;
    }

    // 2. Check Global User Doc
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
        console.error(`\n❌ Global user document 'users/${uid}' DOES NOT EXIST.`);
    } else {
        const userData = userDoc.data();
        console.log(`\n📄 Global User Doc ('users/${uid}'):`, JSON.stringify(userData, null, 2));

        // 3. Check Clinic Memberships
        let clinicIds = userData.clinicIds || [];
        if (clinicIds.length === 0 && userData.primaryClinicId) {
            console.log(`\nℹ️  'clinicIds' missing, using 'primaryClinicId': ${userData.primaryClinicId}`);
            clinicIds = [userData.primaryClinicId];
        }

        if (clinicIds.length === 0 && userData.clinics && Array.isArray(userData.clinics)) {
            console.log(`\nℹ️  'clinicIds' missing, extracting from 'clinics' array.`);
            clinicIds = userData.clinics.map(c => c.clinicId).filter(id => id);
        }

        if (clinicIds.length === 0) {
            console.warn(`\n⚠️ User has NO 'clinicIds' array and no 'primaryClinicId' in global doc.`);
        } else {
            console.log(`\n🏥 User belongs to clinics: ${clinicIds.join(', ')} (Primary: ${userData.primaryClinicId})`);

            for (const clinicId of clinicIds) {
                console.log(`\n--- Inspecting Clinic: ${clinicId} ---`);
                const memberDoc = await db.collection('clinics').doc(clinicId).collection('members').doc(uid).get();
                if (!memberDoc.exists) {
                    console.error(`\n❌ MEMBER DOC MISSING: 'clinics/${clinicId}/members/${uid}' does not exist!`);
                } else {
                    const memberData = memberDoc.data();
                    console.log(`\n✅ Member Doc Found:`, JSON.stringify(memberData, null, 2));
                    console.log(`   - Role: ${memberData.role}`);
                    console.log(`   - Permissions Count: ${memberData.permissions ? memberData.permissions.length : 0}`);

                    // Specific Checks
                    if (memberData.role !== 'owner') {
                        console.warn(`   ⚠️ Role is '${memberData.role}', NOT 'owner'.`);
                    }
                    const missingPerms = [];
                    const CHECK_PERMS = ['viewFinancials', 'viewCalendar', 'viewDoctors', 'manageTeams', 'useCopilot'];
                    if (memberData.permissions) {
                        CHECK_PERMS.forEach(p => {
                            if (!memberData.permissions.includes(p)) missingPerms.push(p);
                        });
                    }
                    if (missingPerms.length > 0) {
                        console.warn(`   ⚠️ MISSING CRITICAL PERMISSIONS: ${missingPerms.join(', ')}`);
                    } else {
                        console.log(`   ✅ Critical permissions present.`);
                    }
                }
            }
        }
    }
}

diagnose().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
