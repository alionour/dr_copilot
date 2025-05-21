import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

Future<void> runFirestoreMigration() async {
  final firestore = FirebaseFirestore.instance;

  // // USERS COLLECTION
  // try {
  //   final usersSnap = await firestore.collection('users').get();
  //   print('Migrating users collection (${usersSnap.docs.length} docs)...');
  //   for (final doc in usersSnap.docs) {
  //     try {
  //       final data = doc.data();
  //       bool needsUpdate = false;
  //       final updates = <String, dynamic>{};

  //       // (users collection will never contain userId field, so skip that logic)
  //       // Ensure ownerId exists and is set to doc.id if missing
  //       if (!data.containsKey('ownerId')) {
  //         updates['ownerId'] = doc.id;
  //         needsUpdate = true;
  //         print('User ${doc.id}: ownerId missing, setting to doc.id');
  //       }

  //       // --- Default clinic creation logic ---
  //       bool shouldCreateDefaultClinic =
  //         !data.containsKey('clinicIds') ||
  //         (data['clinicIds'] is List && (data['clinicIds'] as List).isEmpty) ||
  //         !data.containsKey('primaryClinicId') ||
  //         data['primaryClinicId'] == null;

  //       if (shouldCreateDefaultClinic) {
  //         print('User ${doc.id}: Creating default clinic...');
  //         final clinicsCollection = firestore.collection('clinics');
  //         final newClinicRef = clinicsCollection.doc();
  //         await newClinicRef.set({
  //           'ownerId': updates['ownerId'] ?? data['ownerId'] ?? doc.id,
  //           'createdAt': DateTime.now().toUtc().toIso8601String(),
  //           'name': data['displayName'] ?? data['email'] ?? 'Clinic',
  //           'adminEmail': data['email'] ?? '',
  //         });
  //         final newClinicId = newClinicRef.id;
  //         updates['clinicIds'] = [newClinicId];
  //       }

  //       // If clinicIds exists but is not a list, fix it
  //       else if (data.containsKey('clinicIds') && data['clinicIds'] is! List) {
  //         updates['clinicIds'] = [];
  //         needsUpdate = true;
  //       }

  //       // If primaryClinicId exists but is not a string, fix it
  //       else if (data.containsKey('primaryClinicId') && data['primaryClinicId'] is! String) {
  //         updates['primaryClinicId'] = null;
  //         needsUpdate = true;
  //       }

  //       if (needsUpdate) {
  //         await doc.reference.update(updates);
  //       }
  //     } catch (e, st) {
  //       print('Error migrating user ${doc.id}: $e\n$st');
  //     }
  //   }
  // } catch (e, st) {
  //   print('Error fetching users collection: $e\n$st');
  // }

  // // USER_INVITATIONS COLLECTION
  // try {
  //   final invitesSnap = await firestore.collection('user_invitations').get();
  //   for (final doc in invitesSnap.docs) {
  //     try {
  //       final data = doc.data();
  //       bool needsUpdate = false;
  //       final updates = <String, dynamic>{};
  //       if (data.containsKey('userId')) {
  //         updates['ownerId'] = data['userId'];
  //         updates['userId'] = FieldValue.delete();
  //         needsUpdate = true;
  //       }
  //       if (!data.containsKey('ownerId')) {
  //         updates['ownerId'] = null;
  //         needsUpdate = true;
  //       }
  //       if (!data.containsKey('clinicId')) {
  //         updates['clinicId'] = null;
  //         needsUpdate = true;
  //       }
  //       if (needsUpdate) {
  //         await doc.reference.update(updates);
  //       }
  //     } catch (e, st) {
  //       print('Error migrating user_invitation ${doc.id}: $e\n$st');
  //     }
  //   }
  // } catch (e, st) {
  //   print('Error fetching user_invitations collection: $e\n$st');
  // }

  // // CLINICS COLLECTION
  // try {
  //   final clinicsSnap = await firestore.collection('clinics').get();
  //   for (final doc in clinicsSnap.docs) {
  //     try {
  //       final data = doc.data();
  //       bool needsUpdate = false;
  //       final updates = <String, dynamic>{};
  //       if (data.containsKey('userId')) {
  //         updates['ownerId'] = data['userId'];
  //         updates['userId'] = FieldValue.delete();
  //         needsUpdate = true;
  //       }
  //       if (!data.containsKey('ownerId')) {
  //         updates['ownerId'] = null;
  //         needsUpdate = true;
  //       }
  //       if (needsUpdate) {
  //         await doc.reference.update(updates);
  //       }
  //     } catch (e, st) {
  //       print('Error migrating clinic ${doc.id}: $e\n$st');
  //     }
  //   }
  // } catch (e, st) {
  //   print('Error fetching clinics collection: $e\n$st');
  // }

  // Helper to get clinicId for a given ownerId
  // Future<String?> getClinicIdForOwner(String? ownerId) async {
  //   if (ownerId == null) return null;
  //   try {
  //     final userDoc = await firestore.collection('users').doc(ownerId).get();
  //     final userData = userDoc.data();
  //     if (userData == null) return null;
  //     return userData['primaryClinicId'] ?? (userData['clinicIds'] is List
  //     && (userData['clinicIds'] as List).isNotEmpty ? (userData['clinicIds'] as List).first : null);
  //   } catch (e, st) {
  //     print('Error getting clinicId for owner $ownerId: $e\n$st');
  //     return null;
  //   }
  // }

  // List of collections to migrate
  final collections = [
    'invoices',
    'patients',
    'evaluations',
    'sessions',
    'bills',
    'transactions',
  ];

  for (final collection in collections) {
    try {
      final snap = await firestore.collection(collection).get();
      for (final doc in snap.docs) {
        try {
          debugPrint('Migrating $collection doc ${doc.id}...');

          final updates = <String, dynamic>{};

          // Check if the document has an ownerId field
          String? ownerId = 'ktmgVQ0iJdN2WzhnPCWS4MC4rRz1';
          updates['ownerId'] = ownerId;

          // Check if the document has a clinicId field
          final clinicId = 'n8GSKcqC5J2ijANI3cDU';
          updates['clinicId'] = clinicId;

          // If clinicId exists but is not a string, fix it
          await doc.reference.update(updates);

          debugPrint('Migrated $collection doc ${doc.id}');
        } catch (e, st) {
          debugPrint('Error migrating $collection doc ${doc.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      debugPrint('Error fetching $collection collection: $e\n$st');
    }
  }
}
