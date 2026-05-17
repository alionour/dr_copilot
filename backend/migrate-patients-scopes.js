const admin = require('firebase-admin');

let serviceAccount;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
} else {
  serviceAccount = require('./drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migratePatients() {
  console.log('Starting migration for patient scopes...');
  
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

    if (data.departmentId === undefined) {
      updateData.departmentId = null;
      needsUpdate = true;
    }

    if (data.teamId === undefined) {
      updateData.teamId = null;
      needsUpdate = true;
    }

    if (needsUpdate) {
      batch.update(doc.ref, updateData);
      updatedCount++;
      countInBatch++;
      
      if (countInBatch >= batchSize) {
        await batch.commit();
        console.log(`Committed batch of ${countInBatch} updates.`);
        batch = db.batch();
        countInBatch = 0;
      }
    } else {
      skippedCount++;
    }
  }

  if (countInBatch > 0) {
    await batch.commit();
    console.log(`Committed final batch of ${countInBatch} updates.`);
  }

  console.log('Migration complete!');
  console.log(`Updated: ${updatedCount}`);
  console.log(`Skipped: ${skippedCount}`);
  process.exit(0);
}

migratePatients().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
