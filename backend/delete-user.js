const admin = require('firebase-admin');

let serviceAccount;

if (process.env.GOOGLE_SERVICE_ACCOUNT) {
    try {
        serviceAccount = JSON.parse(process.env.GOOGLE_SERVICE_ACCOUNT);
        console.log('✅ Loaded service account credentials from GOOGLE_SERVICE_ACCOUNT env var.');
    } catch (e) {
        console.error('❌ Failed to parse GOOGLE_SERVICE_ACCOUNT env var:', e);
    }
}

if (!serviceAccount) {
    try {
        serviceAccount = require('./temp_firebase_key.json');
        console.log('✅ Loaded service account credentials from temp_firebase_key.json.');
    } catch (e) {
        // Fallback if not found
    }
}

if (!serviceAccount) {
    try {
        serviceAccount = require('./drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');
        console.log('✅ Loaded service account credentials from local JSON file.');
    } catch (e) {
        console.error('❌ Failed to load local service account file:', e);
    }
}

if (!serviceAccount) {
    console.error('❌ Critical Error: No valid service account credential found in env or local file!');
    process.exit(1);
}

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

const TARGET_EMAIL = 'nourrehabcenter2@gmail.com';

async function deleteUserData() {
    console.log(`--- STARTING CLEANUP FOR USER: ${TARGET_EMAIL} ---\n`);

    try {
        let uid = null;
        let userRecord = null;

        // 1. Find user in Firebase Auth
        try {
            userRecord = await auth.getUserByEmail(TARGET_EMAIL);
            uid = userRecord.uid;
            console.log(`✅ Found user in Firebase Auth. UID: ${uid}`);
        } catch (authError) {
            if (authError.code === 'auth/user-not-found') {
                console.log(`ℹ️ User not found in Firebase Auth. Searching Firestore for orphaned doc...`);
            } else {
                throw authError;
            }
        }

        // If not found in Auth, search Firestore users collection by email
        if (!uid) {
            const userQuery = await db.collection('users')
                .where('email', '==', TARGET_EMAIL)
                .limit(1)
                .get();
            
            if (!userQuery.empty) {
                uid = userQuery.docs[0].id;
                console.log(`✅ Found orphaned user document in Firestore. UID: ${uid}`);
            }
        }

        if (!uid) {
            console.log(`❌ No data found in Auth or Firestore for ${TARGET_EMAIL}. Done.`);
            process.exit(0);
        }

        // 2. Fetch the user document from Firestore
        const userDocRef = db.collection('users').doc(uid);
        const userDoc = await userDocRef.get();
        let clinicsToDelete = new Set();

        if (userDoc.exists) {
            const userData = userDoc.data();
            console.log('User document data:', JSON.stringify(userData, null, 2));

            if (userData.primaryClinicId) {
                clinicsToDelete.add(userData.primaryClinicId);
            }
            if (Array.isArray(userData.clinicIds)) {
                userData.clinicIds.forEach(id => clinicsToDelete.add(id));
            }
            if (Array.isArray(userData.clinics)) {
                userData.clinics.forEach(c => {
                    if (c && c.clinicId) clinicsToDelete.add(c.clinicId);
                });
            }
        } else {
            console.log(`ℹ️ Firestore user document not found for UID: ${uid}`);
        }

        // 3. Process clinics created/owned by this user
        for (const clinicId of clinicsToDelete) {
            const clinicDocRef = db.collection('clinics').doc(clinicId);
            const clinicDoc = await clinicDocRef.get();

            if (clinicDoc.exists) {
                const clinicData = clinicDoc.data();
                
                // Only delete the clinic if this user is the owner (prevents deleting shared clinics they were just invited to)
                if (clinicData.ownerId === uid) {
                    console.log(`🧹 Processing clinic ${clinicId} (owned by user):`);

                    // A. Delete clinic members subcollection
                    const membersSnapshot = await clinicDocRef.collection('members').get();
                    for (const memberDoc of membersSnapshot.docs) {
                        await memberDoc.ref.delete();
                        console.log(`   - Deleted clinic member: ${memberDoc.id}`);
                    }

                    // B. Delete subscriptions document
                    await db.collection('subscriptions').doc(clinicId).delete();
                    console.log(`   - Deleted clinic subscription`);

                    // C. Delete the clinic document itself
                    await clinicDocRef.delete();
                    console.log(`   ✅ Deleted clinic document: ${clinicId}`);
                } else {
                    console.log(`ℹ️ User is a member of clinic ${clinicId} but not the owner. Leaving clinic intact.`);
                    
                    // Remove user from clinic members subcollection
                    await clinicDocRef.collection('members').doc(uid).delete();
                    console.log(`   - Removed user from clinic members list`);
                }
            }
        }

        // 4. Delete the Firestore user document
        if (userDoc.exists) {
            await userDocRef.delete();
            console.log(`✅ Deleted Firestore user document: ${uid}`);
        }

        // 5. Delete from Firebase Auth
        if (userRecord) {
            await auth.deleteUser(uid);
            console.log(`✅ Deleted user from Firebase Auth`);
        }

        console.log(`\n🎉 Cleanup complete for ${TARGET_EMAIL}!`);

    } catch (error) {
        console.error('❌ Error during cleanup:', error);
    } finally {
        process.exit(0);
    }
}

deleteUserData();
