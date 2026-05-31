/**
 * migrate-orphaned-conversations.js
 *
 * Migrates messages from orphaned team conversation `0tpm6m4n65h1256nKfzM`
 * (created by old buggy `_startTeamChat` that used `doc().id` instead of
 * `doc(team.id)`) to the canonical conversation `j1ueCISkTQTOmSEJ6zxe`,
 * then deletes the orphan.
 *
 * Usage:
 *   doppler run -- node backend/migrate-orphaned-conversations.js
 *
 * Or with direct service account:
 *   FIREBASE_SERVICE_ACCOUNT='{...}' node backend/migrate-orphaned-conversations.js
 */
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

const ORPHANED_ID = '0tpm6m4n65h1256nKfzM';
const CANONICAL_ID = 'j1ueCISkTQTOmSEJ6zxe';

async function migrateOrphanedConversation() {
  console.log('=== Starting orphaned conversation migration ===');
  console.log(`Orphaned ID:  ${ORPHANED_ID}`);
  console.log(`Canonical ID: ${CANONICAL_ID}`);

  // 1. Fetch orphaned conversation doc
  const orphanedSnap = await db.collection('team_conversations').doc(ORPHANED_ID).get();
  if (!orphanedSnap.exists) {
    console.log('Orphaned conversation does not exist — nothing to migrate.');
    process.exit(0);
  }
  const orphanedData = orphanedSnap.data();
  console.log(`Orphaned createdAt:  ${orphanedData.createdAt.toDate().toISOString()}`);
  console.log(`Orphaned updatedAt:  ${orphanedData.updatedAt.toDate().toISOString()}`);
  console.log(`Orphaned participantIds: ${JSON.stringify(orphanedData.participantIds)}`);
  console.log(`Orphaned metadata: ${JSON.stringify(orphanedData.metadata)}`);

  // 2. Fetch canonical conversation doc
  const canonicalSnap = await db.collection('team_conversations').doc(CANONICAL_ID).get();
  if (!canonicalSnap.exists) {
    console.log('Canonical conversation does not exist — creating it...');
    await db.collection('team_conversations').doc(CANONICAL_ID).set({
      clinicId: orphanedData.clinicId,
      participantIds: orphanedData.participantIds,
      createdAt: orphanedData.createdAt,
      updatedAt: admin.firestore.Timestamp.now(),
      metadata: orphanedData.metadata,
    });
    console.log('Canonical conversation created.');
  } else {
    const canonicalData = canonicalSnap.data();
    console.log(`Canonical createdAt: ${canonicalData.createdAt.toDate().toISOString()}`);
    console.log(`Canonical participantIds: ${JSON.stringify(canonicalData.participantIds)}`);
  }

  // 3. Migrate messages
  const messagesSnap = await db
    .collection('team_conversations')
    .doc(ORPHANED_ID)
    .collection('messages')
    .orderBy('timestamp', 'asc')
    .get();

  console.log(`\nFound ${messagesSnap.docs.length} messages to migrate:`);

  if (messagesSnap.docs.length > 0) {
    const batch = db.batch();

    messagesSnap.docs.forEach((msgDoc) => {
      const msgData = msgDoc.data();
      console.log(`  Migrating: ${msgDoc.id} | ${msgData.timestamp.toDate().toISOString()} | ${msgData.senderId.substring(0, 12)}... | "${(msgData.content || '').substring(0, 60)}"`);

      const newMsgRef = db
        .collection('team_conversations')
        .doc(CANONICAL_ID)
        .collection('messages')
        .doc(msgDoc.id); // Preserve original document ID

      batch.set(newMsgRef, msgData);
    });

    // Update canonical conversation's lastMessage metadata
    const lastMsg = messagesSnap.docs[messagesSnap.docs.length - 1].data();
    batch.update(db.collection('team_conversations').doc(CANONICAL_ID), {
      lastMessage: lastMsg.content || '',
      lastMessageTimestamp: lastMsg.timestamp,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    // Delete the orphaned conversation document (NOT the subcollection — deleting a doc
    // in Firestore does NOT delete its subcollections)
    batch.delete(orphanedSnap.ref);

    await batch.commit();
    console.log(`\n✓ Successfully migrated ${messagesSnap.docs.length} messages.`);
  } else {
    console.log('No messages to migrate.');
    // Delete the empty orphaned doc
    await orphanedSnap.ref.delete();
    console.log('Deleted empty orphaned conversation.');
  }

  // 4. Verify the orphaned conversation's messages subcollection is gone
  // (Firestore may take a moment, but the parent doc is gone)
  const orphanCheck = await db.collection('team_conversations').doc(ORPHANED_ID).get();
  if (!orphanCheck.exists) {
    console.log('✓ Orphaned conversation document confirmed deleted.');
  } else {
    console.log('⚠ Orphaned conversation document still exists (may need manual cleanup).');
  }

  console.log('\n=== Migration complete ===');
  process.exit(0);
}

migrateOrphanedConversation().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
