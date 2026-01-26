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

// User and clinic information from logs
const userId = 'SDuiyjsdDQMwgWwREhuWl2a0ZuS2';
const clinicId = '5SxGa8PWIkAzQQQQmQVK';
const email = 'drcopilot.test7@gmail.com';
const displayName = 'Dr Copilot Tester 7';

async function createMemberRecord() {
    try {
        console.log('Creating member record...');
        console.log(`User ID: ${userId}`);
        console.log(`Clinic ID: ${clinicId}`);

        // Fetch the invitation to get role and permissions
        const invitationsSnapshot = await db.collection('user_invitations')
            .where('email', '==', email)
            .where('clinicId', '==', clinicId)
            .where('status', '==', 'accepted')
            .limit(1)
            .get();

        let role = 'admin';
        let permissions = [];

        if (!invitationsSnapshot.empty) {
            const invitationData = invitationsSnapshot.docs[0].data();
            console.log('Found invitation:', invitationData);

            // Get role from invitation
            if (invitationData.roles && invitationData.roles.length > 0) {
                role = invitationData.roles[0];
            }

            // Get permissions from invitation
            if (invitationData.permissions) {
                permissions = invitationData.permissions;
            }
        } else {
            console.log('No invitation found, using default admin role and permissions');
            // Default admin permissions
            permissions = [
                'viewAllPatients',
                'createPatient',
                'updatePatient',
                'deletePatient',
                'viewAllSessions',
                'createSession',
                'updateSession',
                'deleteSession',
                'viewAllEvaluations',
                'createEvaluation',
                'updateEvaluation',
                'deleteEvaluation',
                'viewFinancials',
                'addFinancialEntry',
                'editFinancialEntry',
                'deleteFinancialEntry',
                'manageDoctors',
                'manageStaff',
                'manageSettings',
                'viewInvitations',
                'sendInvitation',
                'revokeInvitation'
            ];
        }

        // Create member record
        await db.collection('clinics')
            .doc(clinicId)
            .collection('members')
            .doc(userId)
            .set({
                uid: userId,
                email: email,
                displayName: displayName,
                role: role,
                permissions: permissions,
                joinedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

        console.log('✅ Member record created successfully!');
        console.log(`Role: ${role}`);
        console.log(`Permissions: ${permissions.length} permissions assigned`);

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating member record:', error);
        process.exit(1);
    }
}

createMemberRecord();
