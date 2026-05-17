const admin = require('firebase-admin');
const path = require('path');

let serviceAccount;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    console.log("Loaded Firebase credentials from FIREBASE_SERVICE_ACCOUNT environment variable.");
  } catch (e) {
    console.error("Error parsing FIREBASE_SERVICE_ACCOUNT env var:", e);
  }
}

if (!serviceAccount) {
  try {
    const serviceAccountPath = path.join(__dirname, '../assets/google_credentials.json');
    serviceAccount = require(serviceAccountPath);
    console.log("Loaded Firebase credentials from assets/google_credentials.json file.");
  } catch (err) {
    console.error("Could not load credentials from environment or file.");
    process.exit(1);
  }
}

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkNourcenter() {
  console.log("Searching for 'nourcenterreceptionist' or 'receptionist' across all clinics...");
  const clinicsSnapshot = await db.collection('clinics').get();
  let found = false;

  for (const clinicDoc of clinicsSnapshot.docs) {
    const clinicId = clinicDoc.id;
    const membersSnapshot = await clinicDoc.ref.collection('members').get();

    for (const memberDoc of membersSnapshot.docs) {
      const data = memberDoc.data();
      const memberId = memberDoc.id;
      const email = data.email || '';
      const displayName = data.displayName || '';

      if (memberId.toLowerCase().includes('nourcenterreceptionist') || 
          email.toLowerCase().includes('nourcenterreceptionist') || 
          displayName.toLowerCase().includes('nourcenterreceptionist') ||
          memberId.toLowerCase().includes('receptionist') ||
          email.toLowerCase().includes('receptionist') ||
          displayName.toLowerCase().includes('receptionist')) {
        
        found = true;
        console.log(`\n🎉 Found in Clinic: ${clinicId}`);
        console.log(`Member ID: ${memberId}`);
        console.log(`Display Name: ${displayName}`);
        console.log(`Email: ${email}`);
        console.log(`Role: ${data.role}`);
        console.log(`Permissions:`, data.permissions);
        console.log(`linkedDoctorIds:`, data.linkedDoctorIds);
        console.log(`departmentIds:`, data.departmentIds);
        console.log(`teamIds:`, data.teamIds);
      }
    }
  }

  if (!found) {
    console.log("No member containing 'nourcenterreceptionist' or 'receptionist' found.");
  }
}

checkNourcenter();
