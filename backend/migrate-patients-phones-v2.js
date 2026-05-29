const admin = require('firebase-admin');

let serviceAccount;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
} else {
  // Try to find the local service account file
  try {
    serviceAccount = require('./drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');
  } catch (e) {
    console.error('Service account file not found. Please provide it via FIREBASE_SERVICE_ACCOUNT env var.');
    process.exit(1);
  }
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migratePatientPhones() {
  console.log('🚀 Starting migration for patient phone field REPLACEMENT (v2)...');
  console.log('Target: Replace phoneNumber -> phone1 and alternativePhoneNumber -> phone2');

  const patientsSnapshot = await db.collection('patients').get();
  console.log(`Found ${patientsSnapshot.size} patients to check.`);

  let updatedCount = 0;
  let skippedCount = 0;

  const batchSize = 500;
  let batch = db.batch();
  let countInBatch = 0;

  for (const doc of patientsSnapshot.docs) {
    const data = doc.data();
    let needsUpdate = false;
    const updateData = {};

    // 1. phoneNumber -> phone1
    if (data.phoneNumber !== undefined) {
      if (data.phone1 === undefined) {
        updateData.phone1 = data.phoneNumber;
        console.log(`[PHONE1] Patient ${doc.id}: Copying value from phoneNumber`);
      }
      updateData.phoneNumber = admin.firestore.FieldValue.delete();
      needsUpdate = true;
      console.log(`[PHONE1] Patient ${doc.id}: Deleting phoneNumber`);
    }

    // 2. alternativePhoneNumber -> phone2
    if (data.alternativePhoneNumber !== undefined) {
      if (data.phone2 === undefined) {
        updateData.phone2 = data.alternativePhoneNumber;
        console.log(`[PHONE2] Patient ${doc.id}: Copying value from alternativePhoneNumber`);
      }
      updateData.alternativePhoneNumber = admin.firestore.FieldValue.delete();
      needsUpdate = true;
      console.log(`[PHONE2] Patient ${doc.id}: Deleting alternativePhoneNumber`);
    }

    if (needsUpdate) {
      batch.update(doc.ref, updateData);
      updatedCount++;
      countInBatch++;

      if (countInBatch >= batchSize) {
        await batch.commit();
        console.log(`✅ Committed batch of ${countInBatch} updates.`);
        batch = db.batch();
        countInBatch = 0;
      }
    } else {
      skippedCount++;
    }
  }

  if (countInBatch > 0) {
    await batch.commit();
    console.log(`✅ Committed final batch of ${countInBatch} updates.`);
  }

  console.log('\n✨ Migration complete!');
  console.log(`Total Patients: ${patientsSnapshot.size}`);
  console.log(`Updated:        ${updatedCount}`);
  console.log(`Skipped:        ${skippedCount}`);
  process.exit(0);
}

migratePatientPhones().catch(err => {
  console.error('❌ Migration failed:', err);
  process.exit(1);
});
