const admin = require('firebase-admin');

if (!admin.apps.length) {
  let credential;
  const serviceAccountEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (serviceAccountEnv) {
    credential = admin.credential.cert(JSON.parse(serviceAccountEnv));
  } else {
    credential = admin.credential.applicationDefault();
  }
  admin.initializeApp({ credential });
}
const db = admin.firestore();

async function findExactCause() {
  const orphanedId = '0tpm6m4n65h1256nKfzM';
  const activeId = 'j1ueCISkTQTOmSEJ6zxe';

  // 1. Check the orphaned conversation's CREATED vs UPDATED timestamps
  const orphanedSnap = await db.collection('team_conversations').doc(orphanedId).get();
  const oData = orphanedSnap.data();
  console.log('=== ORPHANED CONVERSATION TIMESTAMPS ===');
  console.log(`Created:  ${oData.createdAt.toDate().toISOString()}`);
  console.log(`Updated:  ${oData.updatedAt.toDate().toISOString()}`);

  // 2. Check the active conversation's timestamps
  const activeSnap = await db.collection('team_conversations').doc(activeId).get();
  const aData = activeSnap.data();
  console.log(`\n=== ACTIVE CONVERSATION TIMESTAMPS ===`);
  console.log(`Created:  ${aData.createdAt.toDate().toISOString()}`);
  console.log(`Updated:  ${aData.updatedAt.toDate().toISOString()}`);

  // 3. Check custom_teams/j1ueCISkTQTOmSEJ6zxe data - does it have an 'id' field inside?
  const teamSnap = await db.collection('custom_teams').doc(activeId).get();
  const teamData = teamSnap.data();
  console.log(`\n=== CUSTOM_TEAMS/${activeId} ===`);
  console.log(`Document ID: ${teamSnap.id}`);
  console.log(`Field 'id': ${teamData.id || '(none)'}`);
  console.log(`Field 'name': ${teamData.name}`);
  console.log(`Created: ${teamData.createdAt?.toDate()?.toISOString()}`);

  // 4. Check if there was EVER a custom_teams/0tpm6m4n65h1256nKfzM
  // Firestore doesn't have "existed before" info, but we can check references
  // Check if the orphaned conversation's participantIds[2] (the 3rd person)
  // has any reference to the orphaned convo ID
  const thirdPersonId = oData.participantIds[2];
  console.log(`\n=== THIRD PARTICIPANT ===`);
  console.log(`UID: ${thirdPersonId}`);
  const thirdUserSnap = await db.collection('users').doc(thirdPersonId).get();
  if (thirdUserSnap.exists) {
    console.log(`Display name: ${thirdUserSnap.data().displayName || 'unknown'}`);
  } else {
    console.log('User doc does not exist');
  }

  // 5. Check the ORIGINAL creation: was createTeam() called with team.id = 0tpm6m4n65h1256nKfzM?
  // The createTeam() code: transaction.set(_teamsCollection.doc(team.id), team.toJson());
  // If team.id = 0tpm6m4n65h1256nKfzM, then custom_teams/0tpm6m4n65h1256nKfzM was created
  // and later DELETED. Let's check if there's any trace.
  
  // Check all activity in the orphaned conversation's messages
  console.log(`\n=== ORPHANED CONVERSATION MESSAGES ===`);
  const msgSnap = await db
    .collection('team_conversations')
    .doc(orphanedId)
    .collection('messages')
    .orderBy('timestamp', 'asc')
    .get();
  msgSnap.docs.forEach((doc) => {
    const m = doc.data();
    console.log(`  ${m.timestamp.toDate().toISOString()} | ${m.senderId.substring(0,12)}... | ${m.content}`);
  });

  // 6. Check if the metadata.teamId field in the orphaned conversation 
  // was CHANGED after creation (by looking at Firestore changelog if available)
  // Firestore doesn't keep changelogs. Instead, let's check the actual field
  console.log(`\n=== METADATA COMPARISON ===`);
  console.log(`Orphaned metadata: ${JSON.stringify(oData.metadata)}`);
  console.log(`Active metadata:   ${JSON.stringify(aData.metadata)}`);

  // 7. Key check: Does the orphaned conversation's data exist without `metadata.teamId` being set?
  // If the orphaned was created by _startChatTeam(), then team.id was used as doc ID and as metadata.teamId
  // They'd match. But they DON'T match (doc ID = 0tpm6m4n65h1256nKfzM, metadata.teamId = j1ueCISkTQTOmSEJ6zxe)
  // So the doc was NOT created by _startChatTeam() or createTeam() in their current form
  
  // Let's check if there was a race: maybe createTeam created BOTH with id = 0tpm6m4n65h1256nKfzM
  // Then someone DELETED custom_teams/0tpm6m4n65h1256nKfzM and RECREATED it as j1ueCISkTQTOmSEJ6zxe
  // Then updateTeam() was called which updated team_conversations/0tpm6m4n65h1256nKfzM metadata
  // to point to j1ueCISkTQTOmSEJ6zxe
  // BUT updateTeam() uses team.id as doc ID, so it would update team_conversations/j1ueCISkTQTOmSEJ6zxe
  // NOT team_conversations/0tpm6m4n65h1256nKfzM

  // Unless... updateTeam() was called when team.id = 0tpm6m4n65h1256nKfzM (still the old id)
  // and the metadata was updated to team.id = j1ueCISkTQTOmSEJ6zxe (new id)
  // That would require the CustomTeamModel's .id to be different from the doc ID
  
  console.log(`\n=== CHECKING CustomTeamModel STRUCTURE ===`);
  console.log(`custom_teams doc has 'id' field: ${teamData.id !== undefined}`);
  console.log(`custom_teams doc 'id' value: ${teamData.id || 'undefined'}`);
  console.log(`custom_teams doc ID: ${teamSnap.id}`);
  console.log(`Match: ${teamData.id === teamSnap.id}`);
  
  // 8. Check if there's a mismatch between doc ID and stored id field
  // If CustomTeamModel stores id inside the data AND the doc ID is different,
  // this could explain everything
  if (teamData.id && teamData.id !== teamSnap.id) {
    console.log(`\n⚠ MISMATCH: Firestore doc ID is "${teamSnap.id}" but stored field 'id' is "${teamData.id}"`);
    console.log(`This means createTeam() created the doc with one ID internally,`);
    console.log(`but Firestore assigned a different document ID.`);
    console.log(`OR the team was copied/migrated from one doc to another.`);
  } else {
    console.log(`No mismatch - doc ID and stored id field match.`);
  }

  process.exit(0);
}

findExactCause().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
