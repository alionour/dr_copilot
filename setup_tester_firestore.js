// Firestore Setup Script for Tester Account
// Run: node setup_tester_firestore.js
// Requires: npm install firebase-admin

const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json'); // Update this path

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const TESTER_UID = '6QEq5hMazPaegl2rGwulSgGdXPw1';
const TESTER_EMAIL = 'drcopilot.test@gmail.com';

async function setupTesterAccount() {
    console.log('Setting up Firestore data for tester account...');

    try {
        // 1. Create a test clinic
        const clinicId = 'test_clinic_001';
        await db.collection('clinics').doc(clinicId).set({
            name: 'Dr. Copilot Test Clinic',
            ownerId: TESTER_UID,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: TESTER_UID,
            address: 'Cairo, Egypt',
            phone: '+201234567890'
        });
        console.log('✅ Created test clinic');

        // 2. Create user document
        await db.collection('users').doc(TESTER_UID).set({
            uid: TESTER_UID,
            email: TESTER_EMAIL,
            displayName: 'Dr. Copilot Tester',
            primaryClinicId: clinicId,
            clinicIds: [clinicId],
            clinics: [{
                clinicId: clinicId,
                role: 'admin'
            }],
            ownerId: TESTER_UID,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('✅ Created user document');

        // 3. Create clinic member document
        await db.collection('clinics').doc(clinicId).collection('members').doc(TESTER_UID).set({
            role: 'admin',
            permissions: ['viewAllPatients', 'editPatients', 'deletePatients', 'addPatients'],
            uid: TESTER_UID,
            email: TESTER_EMAIL,
            displayName: 'Dr. Copilot Tester',
            joinedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('✅ Created clinic member document');

        // 4. Create subscription document
        await db.collection('subscriptions').doc(clinicId).set({
            tier: 'free',
            status: 'active',
            clinicId: clinicId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('✅ Created subscription document');

        console.log('\n🎉 Tester account setup complete!');
        console.log(`Clinic ID: ${clinicId}`);
        console.log(`User UID: ${TESTER_UID}`);

    } catch (error) {
        console.error('❌ Error setting up tester account:', error);
    } finally {
        process.exit(0);
    }
}

setupTesterAccount();
