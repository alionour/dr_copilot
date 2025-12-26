import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dr_copilot/firebase_options.dart';

const TESTER_UID = '6QEq5hMazPaegl2rGwulSgGdXPw1';
const CLINIC_ID = 'test_clinic_001';

Future<void> main() async {
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  print('✅ Firebase initialized');

  try {
    // 1. Create clinic document
    print('\n📋 Creating clinic document...');
    await firestore.collection('clinics').doc(CLINIC_ID).set({
      'name': 'Dr. Copilot Test Clinic',
      'ownerId': TESTER_UID,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': TESTER_UID,
      'address': 'Cairo, Egypt',
      'phone': '+201234567890',
    });
    print('✅ Clinic created: $CLINIC_ID');

    // 2. Create user document
    print('\n👤 Creating user document...');
    await firestore.collection('users').doc(TESTER_UID).set({
      'uid': TESTER_UID,
      'email': 'drcopilot.test@gmail.com',
      'displayName': 'Dr. Copilot Tester',
      'primaryClinicId': CLINIC_ID,
      'clinicIds': [CLINIC_ID],
      'clinics': [
        {
          'clinicId': CLINIC_ID,
          'role': 'admin',
        }
      ],
      'ownerId': TESTER_UID,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ User created: $TESTER_UID');

    // 3. Create clinic member document
    print('\n👥 Creating clinic member...');
    await firestore
        .collection('clinics')
        .doc(CLINIC_ID)
        .collection('members')
        .doc(TESTER_UID)
        .set({
      'role': 'admin',
      'permissions': [
        'viewAllPatients',
        'editPatients',
        'deletePatients',
        'addPatients'
      ],
      'uid': TESTER_UID,
      'email': 'drcopilot.test@gmail.com',
      'displayName': 'Dr. Copilot Tester',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Member permissions set');

    // 4. Create subscription document
    print('\n💳 Creating subscription...');
    await firestore.collection('subscriptions').doc(CLINIC_ID).set({
      'tier': 'free',
      'status': 'active',
      'clinicId': CLINIC_ID,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ Subscription created');

    // 5. Seed sample data
    print('\n📦 Seeding sample data...');
    await seedSampleData(firestore, TESTER_UID, CLINIC_ID);

    print('\n🎉 SUCCESS! Tester account is fully set up.');
    print('Clinic ID: $CLINIC_ID');
    print('User UID: $TESTER_UID');
    print('\nYou can now run the screenshot test!');
  } catch (e) {
    print('\n❌ Error: $e');
    rethrow;
  }
}

Future<void> seedSampleData(
    FirebaseFirestore firestore, String uid, String clinicId) async {
  final batch = firestore.batch();

  // 1. Sample Patients
  final patient1 = firestore.collection('patients').doc('patient_001');
  batch.set(patient1, {
    'clinicId': clinicId,
    'name': 'Sarah Millers',
    'age': 34,
    'gender': 'Female',
    'occupation': 'Graphic Designer',
    'address': 'Cairo, Egypt',
    'createdBy': uid,
    'createdAt': FieldValue.serverTimestamp(),
    'phone': '+20123456789',
    'medicalHistory': 'Mild asthma',
  });

  final patient2 = firestore.collection('patients').doc('patient_002');
  batch.set(patient2, {
    'clinicId': clinicId,
    'name': 'John Doe',
    'age': 52,
    'gender': 'Male',
    'occupation': 'Engineer',
    'address': 'Alexandria, Egypt',
    'createdBy': uid,
    'createdAt': FieldValue.serverTimestamp(),
    'phone': '+20111222333',
    'medicalHistory': 'Type 2 Diabetes, Hypertension',
  });

  // 2. Calendar Events
  final now = DateTime.now();
  final event1 = firestore.collection('calendar_events').doc('event_001');
  batch.set(event1, {
    'id': 'event_001',
    'title': 'Consultation: Sarah Millers',
    'startDateTime': Timestamp.fromDate(now.add(Duration(hours: 2))),
    'endDateTime': Timestamp.fromDate(now.add(Duration(hours: 3))),
    'eventType': 'appointment',
    'clinicId': clinicId,
    'createdBy': uid,
    'createdAt': FieldValue.serverTimestamp(),
    'patientId': 'patient_001',
    'description': 'Follow-up on asthma treatment',
    'isClinicWide': false,
  });

  // 3. Conversations
  final conv1 = firestore.collection('conversations').doc('conv_001');
  batch.set(conv1, {
    'id': 'conv_001',
    'userId': uid,
    'title': 'Managing Chronic Hypertension',
    'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: 2))),
    'updatedAt': Timestamp.fromDate(now.subtract(Duration(minutes: 5))),
    'lastMessageSnippet':
        'Start with dual therapy (ACE inhibitor + CCB) given diabetic status...',
  });

  // 4. Messages in conversation
  final msg1 = conv1.collection('messages').doc('msg_001');
  batch.set(msg1, {
    'id': 'msg_001',
    'userId': uid,
    'senderId': uid,
    'text':
        'How should I manage a 55-year-old male with Stage 2 Hypertension and Type 2 Diabetes?',
    'timestamp': Timestamp.fromDate(now.subtract(Duration(minutes: 10))),
    'type': 'text',
    'isUser': true,
  });

  final msg2 = conv1.collection('messages').doc('msg_002');
  batch.set(msg2, {
    'id': 'msg_002',
    'userId': uid,
    'senderId': 'dr_copilot_ai',
    'text':
        'For this patient, I recommend:\n\n1. **Dual Therapy**: Start with ACE inhibitor + CCB given the diabetic status\n2. **Monitoring**: Regular kidney function tests\n3. **Lifestyle**: Diet modification and exercise program\n4. **Target**: BP <130/80 mmHg for diabetic patients',
    'timestamp': Timestamp.fromDate(now.subtract(Duration(minutes: 5))),
    'type': 'text',
    'isUser': false,
  });

  // 5. Financial Transactions
  final trans1 = firestore.collection('transactions').doc('trans_001');
  batch.set(trans1, {
    'id': 'trans_001',
    'amount': 250.0,
    'description': 'Clinic Consultation - Sarah Millers',
    'transactionDate': FieldValue.serverTimestamp(),
    'transactionSource': 'invoice',
    'direction': 'in',
    'createdAt': FieldValue.serverTimestamp(),
    'ownerId': uid,
    'clinicId': clinicId,
    'status': 'Completed',
    'referenceId': 'INV-2025-001',
  });

  final trans2 = firestore.collection('transactions').doc('trans_002');
  batch.set(trans2, {
    'id': 'trans_002',
    'amount': 120.0,
    'description': 'Medical Equipment Supplies',
    'transactionDate': Timestamp.fromDate(now.subtract(Duration(days: 1))),
    'transactionSource': 'bill',
    'direction': 'out',
    'createdAt': FieldValue.serverTimestamp(),
    'ownerId': uid,
    'clinicId': clinicId,
    'status': 'Completed',
    'referenceId': 'BILL-2025-042',
  });

  await batch.commit();
  print('✅ Sample data seeded (patients, events, conversations, transactions)');
}
