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

// Cache of patientId -> clinicId to avoid redundant queries
const patientClinicCache = {};

async function getClinicIdForPatient(patientId) {
  if (!patientId) return null;
  if (patientClinicCache[patientId] !== undefined) {
    return patientClinicCache[patientId];
  }

  try {
    const patientDoc = await db.collection('patients').doc(patientId).get();
    if (patientDoc.exists) {
      const clinicId = patientDoc.data().clinicId;
      patientClinicCache[patientId] = clinicId;
      return clinicId;
    }
  } catch (error) {
    console.error(`Error fetching patient ${patientId}:`, error.message);
  }
  
  patientClinicCache[patientId] = null;
  return null;
}

async function migrateCollection(collectionName) {
  console.log(`Starting migration for ${collectionName}...`);
  
  const snapshot = await db.collection(collectionName).get();
  console.log(`Found ${snapshot.size} documents in ${collectionName}.`);
  
  let updatedCount = 0;
  let skippedCount = 0;
  let errorCount = 0;
  
  const batchSize = 500;
  let batch = db.batch();
  let countInBatch = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    
    // Check if clinicId is missing or empty
    if (!data.clinicId) {
      const patientId = data.patientId;
      const clinicId = await getClinicIdForPatient(patientId);
      
      if (clinicId) {
        batch.update(doc.ref, { clinicId: clinicId });
        updatedCount++;
        countInBatch++;
        
        if (countInBatch >= batchSize) {
          await batch.commit();
          console.log(`Committed batch of ${countInBatch} updates for ${collectionName}.`);
          batch = db.batch();
          countInBatch = 0;
        }
      } else {
        console.warn(`No clinicId found for patient ${patientId} in doc ${doc.id}`);
        errorCount++;
      }
    } else {
      skippedCount++;
    }
  }

  if (countInBatch > 0) {
    await batch.commit();
    console.log(`Committed final batch of ${countInBatch} updates for ${collectionName}.`);
  }

  console.log(`Finished ${collectionName} migration.`);
  console.log(`Updated: ${updatedCount}, Skipped (already had clinicId): ${skippedCount}, Errors/No Patient: ${errorCount}\n`);
}

async function start() {
  await migrateCollection('medications');
  await migrateCollection('medical_files');
  console.log('All migrations completed successfully.');
  process.exit(0);
}

start().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
