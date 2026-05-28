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

async function migratePatientFields() {
  console.log('🚀 Starting migration for patient field standardisation...');
  console.log('Target: Convert userId -> ownerId and phone -> phoneNumber');

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

    // 1. userId -> ownerId
    if (!data.ownerId && data.userId) {
      updateData.ownerId = data.userId;
      needsUpdate = true;
      console.log(`[ID FIX] Patient ${doc.id}: Setting ownerId from userId`);
    }

    // 2. phone -> phoneNumber
    if (!data.phoneNumber && data.phone) {
      updateData.phoneNumber = data.phone;
      needsUpdate = true;
      console.log(`[PHONE FIX] Patient ${doc.id}: Setting phoneNumber from phone`);
    }

    // 3. Ensure deletedAt exists (required for soft delete filter)
    if (data.deletedAt === undefined) {
      updateData.deletedAt = null;
      needsUpdate = true;
      console.log(`[SOFT DELETE FIX] Patient ${doc.id}: Initialising deletedAt to null`);
    }

    // 4. Optional: Clean up nulls for required UI fields
    if (data.gender === undefined || data.gender === null) {
      // If we don't know, we can't really guess, but we could set a default
      // However, it's better to just ensure the field exists if the model requires it
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

migratePatientFields().catch(err => {
  console.error('❌ Migration failed:', err);
  process.exit(1);
});
