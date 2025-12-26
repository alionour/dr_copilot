import { Firestore } from '@google-cloud/firestore';

const TESTER_UID = '6QEq5hMazPaegl2rGwulSgGdXPw1';
const CLINIC_ID = 'test_clinic_001';

// Parse service account from environment variable
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT || '{}');

// Initialize Firestore using service account
const firestore = new Firestore({
    projectId: serviceAccount.project_id || 'drcopilot-db6ac',
    credentials: serviceAccount,
});

async function setupTesterData() {
    console.log('🔥 Setting up Firestore data for tester account...\n');

    try {
        // 1. Create clinic
        console.log('📋 Creating clinic...');
        await firestore.collection('clinics').doc(CLINIC_ID).set({
            name: 'Dr. Copilot Test Clinic',
            ownerId: TESTER_UID,
            createdAt: Firestore.Timestamp.now(),
            createdBy: TESTER_UID,
            address: 'Cairo, Egypt',
            phone: '+201234567890',
        });
        console.log('✅ Clinic created\n');

        // 2. Create user
        console.log('👤 Creating user...');
        await firestore.collection('users').doc(TESTER_UID).set({
            uid: TESTER_UID,
            email: 'drcopilot.test@gmail.com',
            displayName: 'Dr. Copilot Tester',
            primaryClinicId: CLINIC_ID,
            clinicIds: [CLINIC_ID],
            clinics: [{ clinicId: CLINIC_ID, role: 'admin' }],
            ownerId: TESTER_UID,
            createdAt: Firestore.Timestamp.now(),
        });
        console.log('✅ User created\n');

        // 3. Create member
        console.log('👥 Creating clinic member...');
        await firestore
            .collection('clinics')
            .doc(CLINIC_ID)
            .collection('members')
            .doc(TESTER_UID)
            .set({
                role: 'admin',
                permissions: ['viewAllPatients', 'editPatients', 'deletePatients', 'addPatients'],
                uid: TESTER_UID,
                email: 'drcopilot.test@gmail.com',
                displayName: 'Dr. Copilot Tester',
                joinedAt: Firestore.Timestamp.now(),
            });
        console.log('✅ Member created\n');

        // 4. Create subscription
        console.log('💳 Creating subscription...');
        await firestore.collection('subscriptions').doc(CLINIC_ID).set({
            tier: 'free',
            status: 'active',
            clinicId: CLINIC_ID,
            createdAt: Firestore.Timestamp.now(),
        });
        console.log('✅ Subscription created\n');

        // 5. Seed sample data
        console.log('📦 Seeding sample data...');
        await seedSampleData();
        console.log('✅ Sample data seeded\n');

        console.log('🎉 SUCCESS! Tester account is ready!');
        console.log(`\nClinic ID: ${CLINIC_ID}`);
        console.log(`User UID: ${TESTER_UID}`);
        console.log('\nYou can now run the screenshot test!');
    } catch (error) {
        console.error('\n❌ Error:', error.message);
        process.exit(1);
    }
}

async function seedSampleData() {
    const batch = firestore.batch();
    const now = new Date();

    // Patients
    batch.set(firestore.collection('patients').doc('patient_001'), {
        clinicId: CLINIC_ID,
        name: 'Sarah Millers',
        age: 34,
        gender: 'Female',
        occupation: 'Graphic Designer',
        address: 'Cairo, Egypt',
        createdBy: TESTER_UID,
        createdAt: Firestore.Timestamp.now(),
        phone: '+20123456789',
        medicalHistory: 'Mild asthma',
    });

    batch.set(firestore.collection('patients').doc('patient_002'), {
        clinicId: CLINIC_ID,
        name: 'John Doe',
        age: 52,
        gender: 'Male',
        occupation: 'Engineer',
        address: 'Alexandria, Egypt',
        createdBy: TESTER_UID,
        createdAt: Firestore.Timestamp.now(),
        phone: '+20111222333',
        medicalHistory: 'Type 2 Diabetes, Hypertension',
    });

    // Calendar event
    batch.set(firestore.collection('calendar_events').doc('event_001'), {
        id: 'event_001',
        title: 'Consultation: Sarah Millers',
        startDateTime: Firestore.Timestamp.fromDate(new Date(now.getTime() + 2 * 60 * 60 * 1000)),
        endDateTime: Firestore.Timestamp.fromDate(new Date(now.getTime() + 3 * 60 * 60 * 1000)),
        eventType: 'appointment',
        clinicId: CLINIC_ID,
        createdBy: TESTER_UID,
        createdAt: Firestore.Timestamp.now(),
        patientId: 'patient_001',
        description: 'Follow-up on asthma treatment',
        isClinicWide: false,
    });

    // Conversation
    batch.set(firestore.collection('conversations').doc('conv_001'), {
        id: 'conv_001',
        userId: TESTER_UID,
        title: 'Managing Chronic Hypertension',
        createdAt: Firestore.Timestamp.fromDate(new Date(now.getTime() - 2 * 60 * 60 * 1000)),
        updatedAt: Firestore.Timestamp.fromDate(new Date(now.getTime() - 5 * 60 * 1000)),
        lastMessageSnippet: 'Start with dual therapy (ACE inhibitor + CCB)...',
    });

    // Messages
    batch.set(
        firestore.collection('conversations').doc('conv_001').collection('messages').doc('msg_001'),
        {
            id: 'msg_001',
            userId: TESTER_UID,
            senderId: TESTER_UID,
            text: 'How should I manage a 55yo male with Stage 2 Hypertension and Diabetes?',
            timestamp: Firestore.Timestamp.fromDate(new Date(now.getTime() - 10 * 60 * 1000)),
            type: 'text',
            isUser: true,
        }
    );

    batch.set(
        firestore.collection('conversations').doc('conv_001').collection('messages').doc('msg_002'),
        {
            id: 'msg_002',
            userId: TESTER_UID,
            senderId: 'dr_copilot_ai',
            text: 'For this patient, start with dual therapy (ACE inhibitor + CCB) given diabetic status. Monitor kidney function regularly.',
            timestamp: Firestore.Timestamp.fromDate(new Date(now.getTime() - 5 * 60 * 1000)),
            type: 'text',
            isUser: false,
        }
    );

    // Transactions
    batch.set(firestore.collection('transactions').doc('trans_001'), {
        id: 'trans_001',
        amount: 250.0,
        description: 'Clinic Consultation - Sarah Millers',
        transactionDate: Firestore.Timestamp.now(),
        transactionSource: 'invoice',
        direction: 'in',
        createdAt: Firestore.Timestamp.now(),
        ownerId: TESTER_UID,
        clinicId: CLINIC_ID,
        status: 'Completed',
        referenceId: 'INV-2025-001',
    });

    batch.set(firestore.collection('transactions').doc('trans_002'), {
        id: 'trans_002',
        amount: 120.0,
        description: 'Medical Equipment Supplies',
        transactionDate: Firestore.Timestamp.fromDate(new Date(now.getTime() - 24 * 60 * 60 * 1000)),
        transactionSource: 'bill',
        direction: 'out',
        createdAt: Firestore.Timestamp.now(),
        ownerId: TESTER_UID,
        clinicId: CLINIC_ID,
        status: 'Completed',
        referenceId: 'BILL-2025-042',
    });

    await batch.commit();
}

setupTesterData();
